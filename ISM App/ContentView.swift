//
//  ContentView.swift
//  ISM App
//

import SwiftUI
import CoreBluetooth

class BluetoothViewModel : NSObject, ObservableObject {
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withServices: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "unnamed device")
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    NavigationLink(destination: BluetoothView()) {
                        Text("Connect to Mirror")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("Mirror Settings")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(30)
                Spacer()
            }
        
            .navigationTitle("Home Page")
        }
    }
}

struct BluetoothView: View {
    @ObservedObject private var bluetoothViewModel = BluetoothViewModel()
    
    var body: some View {
        NavigationView {
            List(bluetoothViewModel.peripheralNames, id: \.self) { peripheral in
                Text (peripheral)
            }
        }
        .navigationTitle("Available Devices")
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Text("Setting 1")
                Text("Setting 2")
                Text("Setting 3")
                Text("Setting 4")
                Text("Setting 5")
            }
        }
        .navigationTitle("Mirror Settings")
    }
}

#Preview {
    ContentView()
}
