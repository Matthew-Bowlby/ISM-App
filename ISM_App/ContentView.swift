//
//  ContentView.swift
//  ISM App
//

import SwiftUI
import HealthKitUI

struct ContentView: View {
    @State private var isConnected: Bool = false
    @State private var HKtrigger: Bool = false
    @State private var authorization: Bool = false
    @State private var showingAlert = false
    @State private var bluetoothDebugToggle = false
    @State private var healthDataToggle = false
    @State private var dots = "."
    @State private var timer: Timer?
    @ObservedObject var bluetoothManager = BluetoothManager()
    var healthDataManager = HealthDataManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                 
                if isConnected {
                    // Disconnect button.
                    Button(action: {
                        isConnected = false
                        bluetoothManager.sendCommand(command: SendData(data: "Disconnected".data(using: .utf8)!))
                        bluetoothManager.disconnect()
                    }) {
                        Text("Disconnect")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Settings button.
                    NavigationLink(destination: SettingsView(isConnected: $isConnected, bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager)) {
                        Text("Mirror Settings")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    Spacer()
                                   
                    // Green connected text.
                    Text("Connected")
                        .font(.title)
                        .foregroundColor(.green)
                    .padding(100)
                    Spacer()
                    
                }
                else {
                    if healthDataToggle {
                        // Connect button.
                        Button(action: {
                            guard let peripheral = bluetoothManager.esp32Peripheral else { return }
                            bluetoothManager.connect() { success in
                                if success {
                                    // Connection successful, send the command
                                    isConnected = true
                                    bluetoothManager.sendCommand(command: SendData(data: "Connected".data(using: .utf8)!))
                                } else {
                                    // Connection failed, handle the error
                                    isConnected = false
                                    print("Failed to connect to the device.")
                                }
                            }
                        }) {
                            Text("Connect")
                                .font(.system(size: 28))
                                .padding(15)
                                .padding([.leading, .trailing])
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                            
                        }
                        .disabled(bluetoothManager.esp32Peripheral == nil)
                        .buttonStyle(PlainButtonStyle())
                        .onAppear() {
                            if HKHealthStore.isHealthDataAvailable() {
                                HKtrigger.toggle()
                            }
                        }
                        .healthDataAccessRequest(store: healthDataManager.healthStore,
                                                 shareTypes: healthDataManager.typesToRead,
                                                 readTypes: healthDataManager.typesToRead,
                                                 trigger: HKtrigger) { result in
                            switch result {
                                
                            case .success(_):
                                print("HealthKit authorized")
                                healthDataManager.authorization = true
                                healthDataManager.fetchData()
                            case .failure(let error):
                                // Handle the error here.
                                fatalError("*** An error occurred while requesting authentication: \(error) ***")
                            }
                        }
                    }
                    else {
                        // Connect button.
                        Button(action: {
                            guard let peripheral = bluetoothManager.esp32Peripheral else { return }
                            bluetoothManager.connect() { success in
                                if success {
                                    // Connection successful, send the command
                                    isConnected = true
                                    bluetoothManager.sendCommand(command: SendData(data: "Connected".data(using: .utf8)!))
                                } else {
                                    // Connection failed, handle the error
                                    isConnected = false
                                    print("Failed to connect to the device.")
                                }
                            }
                        }) {
                            Text("Connect")
                                .font(.system(size: 28))
                                .padding(15)
                                .padding([.leading, .trailing])
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(30)
                            
                        }
                        .disabled(bluetoothManager.esp32Peripheral == nil)
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // If the esp32 isn't found, display that it is searching and the most recent device scanned.
                    if bluetoothDebugToggle {
                        if bluetoothManager.esp32Peripheral == nil {
                            // Searching ... animation
                            Text("Searching \(dots)")
                                .onAppear {
                                    self.startAnimating()
                                }
                                .onDisappear {
                                    self.stopAnimating()
                                }
                            
                            // Discovered ____ text
                            let peripheral = String(bluetoothManager.mostRecentPeripheral ?? "")
                            let description = String(bluetoothManager.mostRecentDescription ?? "")
                            if peripheral != "" && description != "" {
                                Text("Discovered \(peripheral): \(description)")
                            }
                        }
                        else {
                            Text("Found Device!")
                        }
                    }
                    // Settings button.
                    NavigationLink(destination: SettingsView(isConnected: $isConnected, bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager)) {
                        Text("Mirror Settings")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    
                    Spacer()
                        
                    // Red disconnected text.
                    Text("Disconnected")
                        .font(.title)
                        .foregroundColor(.red)
                    
                    .padding(100)
                    Spacer()
                }
                Spacer()
                 
            }
        
            .navigationTitle("Home Page")
        }
    }
    
    // Adds . -> .. -> ... animation for Searching text.
    private func startAnimating() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.dots.count < 3 {
                self.dots += "."
            } else {
                self.dots = "."
            }
        }
        timer?.tolerance = 0
    }
    
    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
    }
    
    func sendCommands() {
        bluetoothManager.sendCommand(command: SendData(data: "Test".data(using: .utf8)!))
    }
}

struct SettingsView: View {
    @Binding var isConnected: Bool
    @Binding var bluetoothDebugToggle: Bool
    @Binding var healthDataToggle: Bool
    @ObservedObject var bluetoothManager: BluetoothManager
    var healthDataManager: HealthDataManager
    
    var body: some View {
        Form {
            Toggle("Bluetooth Debug", isOn: $bluetoothDebugToggle)
                .disabled(isConnected)
            Toggle("Send Health Data", isOn: $healthDataToggle)
                .disabled(isConnected)
        }
        .navigationTitle("Mirror Settings")
    }
}

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

