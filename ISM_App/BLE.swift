//
//  ContentView.swift
//  ISM App
//

import Foundation
import CoreBluetooth
import CommonCrypto

// Command structure:
protocol Command {
    var data: Data { get }
}

struct SendData: Command {
    let data: Data
    
    init(data: Data) {
        self.data = data
    }
}

class BluetoothManager : NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    @Published var esp32Peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private let esp32ServiceUUID = CBUUID(string: "c0fe")
    private let characteristicUUID = CBUUID(string: "3dee")
    
    var mostRecentPeripheral: String? = nil     // Most recent peripheral scanned.
    @Published var isConnected: Bool = false    // If BLE is connected.

    var toSend: [(String, String)] = []         // Information to be sent over BLE.
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
    
    // Sends the commands in the toSend list.
    func allCommands() {
        if toSend.isEmpty { return }
            
        for (item, number) in toSend {
            //print(item, number)
            if number == "" {
                sendCommand(command: SendData(data: "\(item)".data(using: .utf8)!))
            }
            else {
                sendCommand(command: SendData(data: "\(item): \(number)".data(using: .utf8)!))
            }
        }
    }
}

// Central Manager
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
            print("Bluetooth is powered on.")
        case .poweredOff:
            // Handle powered off state
            print("Bluetooth is powered off.")
        case .resetting:
            // Handle resetting state
            print("Bluetooth is resetting.")
        case .unauthorized:
            // Handle unauthorized state
            print("Unauthorized to use Bluetooth.")
        case .unsupported:
            // Handle unsupported state
            print("Bluetooth is not supported on this device.")
        case .unknown:
            // Handle unknown state
            print("Bluetooth state is unknown.")
        @unknown default:
            fatalError("Unhandled Bluetooth state.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = String(describing: peripheral.name)
        
        // Set most recent peripheral discovered.
        if name != "nil" {
            mostRecentPeripheral = peripheral.name
        }
        
        // If the most recent peripheral is the ESP32, stop scanning and set the peripheral to connect.
        if peripheral.name == "ESP32-BLE-Server" {
            print("Found Device!")
            esp32Peripheral = peripheral
            centralManager?.stopScan()
        }
    }
    
    // Handles connection, getting service UUID from ESP32.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        peripheral.discoverServices([esp32ServiceUUID])
    }
    
    // Handles disconnection if the ESP32 disconnects.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral disconnected")
        isConnected = false
    }
    
    // Handles Connect button press, performing actual connection to the ESP32.
    func connect(completion: @escaping (Bool) -> Void) {
        // Check if esp32Peripheral is not nil.
         guard let peripheral = self.esp32Peripheral else {
             print("Error: Peripheral is nil")
             return
         }
         
         // Check if centralManager is powered on.
         guard centralManager?.state == .poweredOn else {
             print("Error: Bluetooth is not powered on")
             return
         }

         if centralManager?.delegate == nil {
             centralManager?.delegate = self
         }
         centralManager?.connect(peripheral, options: nil)
        
         // 1.5 second delay to prevent race conditions.
         DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
             if peripheral.state == .connected {
                 completion(true)
             } else {
                 completion(false)
             }
         }
    }
    
    // Handles Disconnect button, disconnecting the ESP32.
    func disconnect() {
        guard let peripheral = self.esp32Peripheral else {
            print("Error: No peripheral connected.")
            return
        }
        centralManager?.cancelPeripheralConnection(peripheral)
        isConnected = false
        print("Disconnected.")
    }
}


extension BluetoothManager: CBPeripheralDelegate {
    // Gets characteristic UUID from ESP32.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services discovered.")
            return
        }
        
        for service in services {
            if service.uuid == esp32ServiceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
                break
            }
        }
    }
    
    // Performs function to grab characteristic UUID.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics for service \(service.uuid): \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics discovered for service \(service.uuid)")
            return
        }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                self.commandCharacteristic = characteristic
                print("Found command characteristic: \(characteristic.uuid)")
            }
        }
    }
    
    // Performs AES-128 encryption.
    func encryptAES(data: Data, key: Data, iv: Data) throws -> Data {
        var encryptedData = Data(count: data.count + kCCBlockSizeAES128)
        var encryptedLength: Int = 0
        
        let status = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                data.withUnsafeBytes { dataBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding),
                        keyBytes.baseAddress, key.count,
                        ivBytes.baseAddress,
                        dataBytes.baseAddress, data.count,
                        encryptedData.withUnsafeMutableBytes { $0.baseAddress }, encryptedData.count,
                        &encryptedLength
                    )
                }
            }
        }
        
        guard status == kCCSuccess else {
            throw NSError(domain: "encryptionError", code: Int(status), userInfo: nil)
        }
        
        encryptedData.removeSubrange(encryptedLength..<encryptedData.count)
        return encryptedData
    }
    
    // Converts base64 output of AES-128 encryption to hex.
    private func base64ToHex(_ base64String: String) -> String? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }

        let hexString = data.map { String(format: "%02hhx", $0) }.joined()
        return hexString
    }
    
    // Sends string containing information to the ESP32.
    func sendCommand(command: Command) {
        guard let peripheral = self.esp32Peripheral, let characteristic = self.commandCharacteristic else {
            print("Error: ESP32 not connected or characteristic not found.")
            return
        }

        let keyString = "18C3D531F1066FBD"
        let ivString = "C4D4C429A046ADDD"

        guard let key = keyString.data(using: .utf8),
              let iv = ivString.data(using: .utf8) else {
            fatalError("Failed to convert string to data")
        }

        do {
            let encryptedData = try encryptAES(data: command.data + "+".data(using: .utf8)!, key: key, iv: iv)
            let encryptedString = base64ToHex(encryptedData.base64EncodedString())
            print("Encrypted string: \(encryptedString!)")
            peripheral.writeValue(encryptedString!.data(using: .utf8)!, for: characteristic, type: .withResponse)
        } catch {
            print("Encryption error: \(error.localizedDescription)")
        }
    }
}

