//
//  ContentView.swift
//  ISM App
//

import Foundation
import CoreBluetooth

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
    
    var mostRecentPeripheral: String? = nil
    var mostRecentDescription: String? = nil

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
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
        let rssi = RSSI.intValue
        
        if name != "nil" {
            print("Discovered \(name) at \(rssi)")
            mostRecentPeripheral = peripheral.name
            mostRecentDescription = peripheral.description
        }
        
        if peripheral.name == "ESP32-BLE-Server" {
            print("Found Device!")
            esp32Peripheral = peripheral
            centralManager?.stopScan()
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        peripheral.delegate = self
        peripheral.discoverServices([esp32ServiceUUID])
    }

    func connect(completion: @escaping (Bool) -> Void) {
        // Check if esp32Peripheral is not nil
         guard let peripheral = self.esp32Peripheral else {
             print("Error: Peripheral is nil")
             return
         }
         
         // Check if centralManager is powered on
         guard centralManager?.state == .poweredOn else {
             print("Error: Bluetooth is not powered on")
             return
         }
         
         // Set central manager delegate if not already set
         if centralManager?.delegate == nil {
             centralManager?.delegate = self
         }
         
         // Attempt to connect to the peripheral
         centralManager?.connect(peripheral, options: nil)
        
         // 1.5 second delay currently.
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
             if peripheral.state == .connected {
                 completion(true)
             } else {
                 completion(false)
             }
         }
    }
    
    func disconnect() {
        guard let peripheral = self.esp32Peripheral else {
            print("Error: No peripheral connected.")
            return
        }
        centralManager?.cancelPeripheralConnection(peripheral)
        print("Disconnected.")
    }
    
    // Check if peripheral is still connected.
    func checkPeripheralActivity() -> Bool {
        guard let peripheral = esp32Peripheral else {
            return false
        }
        
        return peripheral.state == .connected
    }
}


extension BluetoothManager: CBPeripheralDelegate {
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
    
    func sendCommand(command: Command) {
        guard let peripheral = self.esp32Peripheral, let characteristic = self.commandCharacteristic else {
            print("Error: ESP32 not connected or characteristic not found.")
            return
        }
        peripheral.writeValue(command.data, for: characteristic, type: .withResponse)
    }
}

