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
                    Spacer()
                    Text("Connected")
                        .font(.title)
                        .foregroundColor(.green)
                    .padding(100)
                    Spacer()
                }
                else {
                    Button(action: {
                        guard let peripheral = bluetoothManager.esp32Peripheral else { return }
                        bluetoothManager.connectToDevice() { success in
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
                    Spacer()
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
}

/*
struct SettingsView: View {
    @Binding var isConnected: Bool
    @Binding var isHKEnabled: Bool
    var healthDataManager: HealthDataManager
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Button(action: {
                showingPermissionAlert = true
            }) {
                Text("Enable HealthKit")
            }
            .disabled(isConnected)
            
        }
        .navigationTitle("Mirror Settings")
        .alert(isPresented: $showingPermissionAlert) {
            Alert(title: Text("Permission Required"),
                  message: Text("Please grant permission to access HealthKit data."),
                  primaryButton: .default(Text("Grant")) {
                healthDataManager.requestAuthorization()
            },
                  secondaryButton: .cancel())
        }
    }
}
*/

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

