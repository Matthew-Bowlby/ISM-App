//
//  ContentView.swift
//  ISM App
//

import SwiftUI

struct ContentView: View {
    @State private var isConnected: Bool = false
    // private let bluetoothManager = BluetoothManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if isConnected {
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Text("Mirror Settings")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                    }
                    
                    
                    Text("Connected")
                        .font(.title)
                        .foregroundColor(.green)
                    .padding(100)
                    Spacer()
                }
                else {
                    Spacer()
                    Button(action: {
                        // bluetoothManager.connectToDevice()
                        isConnected = true
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

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

