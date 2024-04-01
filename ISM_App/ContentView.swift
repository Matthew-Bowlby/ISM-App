//
//  ContentView.swift
//  ISM App
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var HKtrigger: Bool = false
    @State private var authorization: Bool = false
    @State private var showingAlert = false
    @State private var bluetoothDebugToggle = true
    @State private var healthDataToggle = false
    @State private var weatherDataToggle = false
    @State private var dots = "."
    @State private var timer: Timer?
    
    @ObservedObject var bluetoothManager = BluetoothManager()
    @ObservedObject var healthDataManager = HealthDataManager()
    var weatherDataManager = WeatherDataManager()
    @ObservedObject var locationDataManager = LocationDataManager()
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                 
                if bluetoothManager.isConnected {
                    // Disconnect button.
                    Button(action: {
                        bluetoothManager.sendCommand(command: SendData(data: "Disconnected".data(using: .utf8)!))
                        healthDataManager.stopFetchData()
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
                    NavigationLink(destination: SettingsView(bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, weatherDataToggle: $weatherDataToggle, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager, weatherDataManager: weatherDataManager, locationDataManager: locationDataManager)) {
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
                        guard bluetoothManager.esp32Peripheral != nil else { return }
                        bluetoothManager.connect() { success in
                            if success {
                                // Connection successful, send the command
                                bluetoothManager.isConnected = true
                                bluetoothManager.sendCommand(command: SendData(data: "Connected".data(using: .utf8)!))
                            } else {
                                // Connection failed, handle the error
                                bluetoothManager.isConnected = false
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

                    // Settings button.
                    NavigationLink(destination: SettingsView(bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, weatherDataToggle: $weatherDataToggle, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager, weatherDataManager: weatherDataManager, locationDataManager: locationDataManager)) {
                        Text("Mirror Settings")
                            .font(.system(size: 28))
                            .padding(15)
                            .padding([.leading, .trailing])
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(30)
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
                            if peripheral != "" {
                                Text("Discovered \(peripheral)")
                            }
                        }
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
            .navigationTitle("Home")
            .modifier(ColorSchemeModifier(colorScheme: colorScheme))
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
}

struct SettingsView: View {
    @Binding var bluetoothDebugToggle: Bool
    @Binding var healthDataToggle: Bool
    @Binding var weatherDataToggle: Bool
    
    @AppStorage("selectedAppearance") var selectedAppearance = 0
    
    var bluetoothManager: BluetoothManager
    var healthDataManager: HealthDataManager
    var weatherDataManager: WeatherDataManager
    var locationDataManager: LocationDataManager
    
    var body: some View {
        Form {
            Picker("Color Scheme", selection: $selectedAppearance) {
                Text("Default System")
                    .tag(0)
                Text("Light")
                    .tag(1)
                Text("Dark")
                    .tag(2)
            }
            .pickerStyle(.inline)
            
            Section("Bluetooth") {
                Toggle("Bluetooth Debug", isOn: $bluetoothDebugToggle)
                    .disabled(bluetoothManager.isConnected)
            }
            Section("Health") {
                Toggle("Show Health Data", isOn: $healthDataToggle)
                    .disabled(!bluetoothManager.isConnected)
            }
            
            Section("Weather") {
                Toggle("Show Weather Data", isOn: $weatherDataToggle)
                    .disabled(!bluetoothManager.isConnected)
            }
            
        }
        .navigationTitle("Settings")
        .onChange(of: healthDataToggle) { newValue in
            if newValue {
                healthDataManager.requestAuthorization()
                
                if bluetoothManager.isConnected {
                    healthDataManager.heartRateCompletion = { heart in
                        DispatchQueue.main.async {
                            print("Sending heart rate")
                            bluetoothManager.sendCommand(command: SendData(data: heart.data(using: .utf8)!))
                        }
                    }
                    healthDataManager.stepCountCompletion = { steps in
                        DispatchQueue.main.async {
                            print("Sending step count")
                            bluetoothManager.sendCommand(command: SendData(data: steps.data(using: .utf8)!))
                        }
                    }
                    healthDataManager.caloriesBurnedCompletion = { cals in
                        DispatchQueue.main.async {
                            print("Sending calories burned")
                            bluetoothManager.sendCommand(command: SendData(data: cals.data(using: .utf8)!))
                        }
                    }
                    /*
                    healthDataManager.restingHeartRateCompletion = { rest in
                        DispatchQueue.main.async {
                            print("Sending resting heart rate")
                            bluetoothManager.sendCommand(command: SendData(data: rest.data(using: .utf8)!))
                        }
                    }
                     */
                    healthDataManager.distanceCompletion = { dist in
                        DispatchQueue.main.async {
                            print("Sending distance running/walking")
                            bluetoothManager.sendCommand(command: SendData(data: dist.data(using: .utf8)!))
                        }
                    }
                    healthDataManager.alcoholCompletion = { alc in
                        DispatchQueue.main.async {
                            print("Sending number of alcoholic beverages")
                            bluetoothManager.sendCommand(command: SendData(data: alc.data(using: .utf8)!))
                        }
                    }
                }
            }
            else {
                if healthDataManager.fetching {
                    print("Stopping HealthKit fetch")
                    healthDataManager.stopFetchData()
                }
            }
        }
        
        .onChange(of: weatherDataToggle) { newValue in
            if newValue {
                if locationDataManager.status {
                    locationDataManager.startServices()
                }
                
                if locationDataManager.authorization == .authorizedWhenInUse {
                    Task {
                        await weatherDataManager.getWeather(latitude: locationDataManager.latitude, longitude: locationDataManager.longitude)
                        print("Temperature: \(weatherDataManager.temperature)")
                        print("Condition: \(weatherDataManager.condition)")
                        print("UV Index: \(weatherDataManager.uvIndex)")
                        print("Humidity: \(weatherDataManager.humidity)")
                        
                        if bluetoothManager.isConnected {
                            bluetoothManager.sendCommand(command: SendData(data: "TempF: \( weatherDataManager.temperature)".data(using: .utf8)!))
                            bluetoothManager.sendCommand(command: SendData(data: "Condi: \(weatherDataManager.condition)".data(using: .utf8)!))
                            bluetoothManager.sendCommand(command: SendData(data: "UVInd: \(weatherDataManager.uvIndex)".data(using: .utf8)!))
                            bluetoothManager.sendCommand(command: SendData(data: "Humid: \(weatherDataManager.humidity)".data(using: .utf8)!))
                        }
                    }
                }
            }
            else {
                locationDataManager.stopServices()
            }
        }
    }
}

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

