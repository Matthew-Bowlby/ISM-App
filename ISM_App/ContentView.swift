//
//  ContentView.swift
//  ISM App
//

import SwiftUI

struct ContentView: View {
    @State private var isConnected: Bool = false
    @State private var isHKEnabled: Bool = false
    //private var bluetoothManager = BluetoothManager()
    //private var healthDataManager = HealthDataManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                NavigationLink(destination: SettingsView(isConnected: $isConnected, isHKEnabled: $isHKEnabled)) {
                    Text("Mirror Settings")
                        .font(.system(size: 28))
                        .padding(15)
                        .padding([.leading, .trailing])
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                }
                if isConnected {
                    Button(action: {
                        // bluetoothManager.disconnect()
                        isConnected = false
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
                        //bluetoothManager.connectToDevice()
                        isConnected = true
                        
                        /*
                        if isHKEnabled {
                            healthDataManager.fetchData(for: .stepCount)
                            healthDataManager.fetchData(for: .exerciseTime)
                            healthDataManager.fetchData(for: .moveTime)
                            healthDataManager.fetchData(for: .standTime)
                            healthDataManager.fetchData(for: .activeEnergyBurned)
                        }
                         */
                    }) {
                        Text("Connect")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            
                    }
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

struct SettingsView: View {
    @Binding var isConnected: Bool
    @Binding var isHKEnabled: Bool
    
    var body: some View {
        Form {
            Toggle(isOn: $isHKEnabled) {
                Text("Enable HealthKit")
            }
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

