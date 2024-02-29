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
    let data: Data = Data([0x01]) // example data, change later
}



class BluetoothManager : NSObject {
    private var centralManager: CBCentralManager!
    private var esp32Peripheral: CBPeripheral?
    private var commandCharacteristic: CBCharacteristic?
    private let esp32ServiceUUID = CBUUID(string: "UUID")
    private let characteristicUUID = CBUUID(string: "UUID")
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

// Central Manager
extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: [esp32ServiceUUID], options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        esp32Peripheral = peripheral
        esp32Peripheral?.delegate = self
        centralManager.connect(esp32Peripheral!, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.discoverServices([esp32ServiceUUID])
    }
    
    func connectToDevice() {
        if let peripheral = esp32Peripheral {
            centralManager.connect(peripheral, options: nil)
        }
    }
}


extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == esp32ServiceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
                break
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                
            }
        }
    }
    
    func sendCommand(command: Command) {
        guard let peripheral = esp32Peripheral, let characteristic = commandCharacteristic else {
            print("Error: ESP32 not connected or characteristic not found.")
            return
        }
        peripheral.writeValue(command.data, for: characteristic, type: .withResponse)
    }
}

