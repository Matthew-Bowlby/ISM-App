//
//  ContentView.swift
//  ISM App
//

import SwiftUI

struct ContentView: View {
    @State private var isConnected: Bool = false
    @State private var isHKEnabled: Bool = false
    @State private var authorization: Bool = false
    @State private var showingAlert = false
    @State private var dots = "."
    @State private var timer: Timer?
    @ObservedObject var bluetoothManager = BluetoothManager()
    //private var healthDataManager = HealthDataManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                /*
                NavigationLink(destination: SettingsView(isConnected: $isConnected, isHKEnabled: $isHKEnabled) {
                    Text("Mirror Settings")
                        .font(.system(size: 28))
                        .padding(15)
                        .padding([.leading, .trailing])
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                 */
                 
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
                    NavigationLink(destination: SettingsView(isConnected: $isConnected, bluetoothManager: bluetoothManager)) {
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
                    
                    // If the esp32 isn't found, display that it is searching and the most recent device scanned.
                    if bluetoothManager.esp32Peripheral == nil {
                        // Searching ... animation
                        Text("Searching \(dots)")
                            .onAppear {
                                self.startAnimating()
                            }
                        
                        // Discovered ____ text
                        let peripheral = String(bluetoothManager.mostRecentPeripheral ?? "")
                        if peripheral != "" {
                            Text("Discovered \(peripheral)")
                        }
                        
                    }
                    else {
                        Text("Found Device!")
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
    func startAnimating() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.dots.count < 3 {
                self.dots += "."
            } else {
                self.dots = "."
            }
        }
    }
    
    func sendCommands() {
        bluetoothManager.sendCommand(command: SendData(data: "Test".data(using: .utf8)!))
    }
}

struct SettingsView: View {
    @Binding var isConnected: Bool
    @ObservedObject var bluetoothManager: BluetoothManager
    //var healthDataManager: HealthDataManager
    //@State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Button(action: {
                bluetoothManager.sendCommand(command: SendData(data: "Test".data(using: .utf8)!))
            }) {
                Text("Example Setting")
            }
            .disabled(isConnected)
            
        }
        .navigationTitle("Mirror Settings")
        /*
        .alert(isPresented: $showingPermissionAlert) {
            Alert(title: Text("Permission Required"),
                  message: Text("Please grant permission to access HealthKit data."),
                  primaryButton: .default(Text("Grant")) {
                healthDataManager.requestAuthorization()
            },
                  secondaryButton: .cancel())
        }
         */
    }
}

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

