//
//  ContentView.swift
//  ISM App
//

import SwiftUI
import Security

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var HKtrigger: Bool = false          // Trigger for HealthKit collection.
    @State private var showingAlert = false             // Boolean determining whether an alert is showing.
    @State private var userInput = ""                   // User input received from initial alert determining username.
    @State private var bluetoothDebugToggle = true
    @State private var healthDataToggle = false
    @State private var weatherDataToggle = false
    @State private var dataToggle = false
    @State private var dots = "."                       // . -> .. -> ... animation for BLE debug.
    @State private var dot_timer: Timer?                // Timer for dot animation.
    @State private var send_timer: Timer?               // Timer for sending information every minute.
    
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
                        print("here")
                        bluetoothManager.sendCommand(command: SendData(data: "Disconnected".data(using: .utf8)!))
                        
                        // Disconnect after 0.5 seconds to prevent race condition.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            healthDataManager.stopFetchData()
                            bluetoothManager.disconnect()
                            
                            // Set toggles to false reliant upon connection.
                            dataToggle = false
                            weatherDataToggle = false
                            healthDataToggle = false
                            
                            send_timer?.invalidate()
                            send_timer = nil
                        }
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
                    NavigationLink(destination: SettingsView(bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, weatherDataToggle: $weatherDataToggle, dataToggle: $dataToggle, userInput: $userInput, send_timer: $send_timer, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager, weatherDataManager: weatherDataManager, locationDataManager: locationDataManager)) {
                        
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
                                 // Connection successful, send the command.
                                 bluetoothManager.isConnected = true
                                 bluetoothManager.sendCommand(command: SendData(data: "Connected".data(using: .utf8)!))
                                 
                                 // Get username from Keychain if set, otherwise get it from alert.
                                 if let username = getUsernameFromKeychain() {
                                     print("\(username)")
                                     userInput = username
                                     bluetoothManager.sendCommand(command: SendData(data: "Name: \(username)".data(using: .utf8)!))
                                 }
                                 else {
                                     print("here")
                                     showingAlert = true
                                 }
                            
                             } else {
                                 // Connection failed, handle the error.
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
                    NavigationLink(destination: SettingsView(bluetoothDebugToggle: $bluetoothDebugToggle, healthDataToggle: $healthDataToggle, weatherDataToggle: $weatherDataToggle, dataToggle: $dataToggle, userInput: $userInput, send_timer: $send_timer, bluetoothManager: bluetoothManager, healthDataManager: healthDataManager, weatherDataManager: weatherDataManager, locationDataManager: locationDataManager)) {
                        
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
                            // Searching ... animation.
                            Text("Searching \(dots)")
                                .onAppear {
                                    self.startAnimating()
                                }
                                .onDisappear {
                                    self.stopAnimating()
                                }
                            
                            // Discovered ____ text.
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
        // Alert handling username grab.
        .alert("Log in", isPresented: $showingAlert) {
            TextField("Username", text: $userInput)
                .textInputAutocapitalization(.words)
            Button("OK", action: saveUsernameToKeychain)
            Button("Cancel", role: .cancel) {
                bluetoothManager.disconnect()
                bluetoothManager.isConnected = false
            }
        } message: {
            Text("Please enter your username.")
        }
    }
    
    // Adds . -> .. -> ... animation for Searching text.
    private func startAnimating() {
        dot_timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if self.dots.count < 3 {
                self.dots += "."
            } else {
                self.dots = "."
            }
        }
        dot_timer?.tolerance = 0
    }
    
    // Stops dot animation.
    private func stopAnimating() {
        dot_timer?.invalidate()
        dot_timer = nil
    }
    
    // Saves new username to Keychain.
    private func saveUsernameToKeychain() {
        let data = Data(userInput.utf8)
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: "username",
            kSecValueData as String: data
        ] as CFDictionary
        
        SecItemDelete(query)
        SecItemAdd(query, nil)
        
        bluetoothManager.sendCommand(command: SendData(data: "Name: \(userInput)".data(using: .utf8)!))
    }
    
    // Grabs username from Keychain.
    private func getUsernameFromKeychain() -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "username",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        if status == errSecSuccess, let data = result as? Data, let username = String(data: data, encoding: .utf8) {
            return username
        } else {
            return nil
        }
    }
}

struct SettingsView: View {
    @Binding var bluetoothDebugToggle: Bool
    @Binding var healthDataToggle: Bool
    @Binding var weatherDataToggle: Bool
    @Binding var dataToggle: Bool
    @Binding var userInput: String              // Username inputted.
    @Binding var send_timer: Timer?             // Same as send_timer in main view.
    
    @State private var brightness = 50.0        // Brightness slider.
    @State private var isEditing = false        // Helper for slider determining if it is currently being moved.
    @State private var showingAlert = false     // Boolean handling alert upon requesting username edit.
    @State private var newUsername = ""         // New username inputted from username edit.
    
    @AppStorage("selectedAppearance") var selectedAppearance = 0    // Light/Dark theme.
    
    var bluetoothManager: BluetoothManager
    var healthDataManager: HealthDataManager
    var weatherDataManager: WeatherDataManager
    var locationDataManager: LocationDataManager
    
    var body: some View {
        Form {
            // Theme.
            Picker("Color Scheme", selection: $selectedAppearance) {
                Text("Default System")
                    .tag(0)
                Text("Light")
                    .tag(1)
                Text("Dark")
                    .tag(2)
            }
            .pickerStyle(.inline)
            
            // Edit username.
            Section("Username") {
                Button(action: {
                    showingAlert = true
                }) {
                    Text("Edit Username")
                        .foregroundColor((userInput != "") ? .blue : .gray)
                }
                .disabled(userInput == "")
            }
            
            // Brightness slider.
            Section("LED Brightness") {
                Slider(
                    value: $brightness,
                    in: 0...100,
                    step: 10
                ) {
                    Text("Brightness")
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("100")
                } onEditingChanged: { editing in
                    isEditing = editing
                    if !editing {
                        print("\(brightness)")
                        bluetoothManager.sendCommand(command: SendData(data: "Name: \(userInput)".data(using: .utf8)!))
                        bluetoothManager.sendCommand(command: SendData(data: "Bright: \(brightness)".data(using: .utf8)!))
                    }
                }
                .disabled(!bluetoothManager.isConnected)
                
                Text("\(brightness)")
                    .foregroundColor(isEditing ? .red : .blue)
                    .multilineTextAlignment(.center)
            }
            
            // Bluetooth debug.
            Section("Bluetooth") {
                Toggle("Bluetooth Debug", isOn: $bluetoothDebugToggle)
                    .disabled(bluetoothManager.isConnected)
            }
            
            // Data toggles to collect and send data.
            Section("Data") {
                Toggle("Collect Health Data", isOn: $healthDataToggle)
                    .disabled(!bluetoothManager.isConnected)
                Toggle("Collect Weather Data", isOn: $weatherDataToggle)
                    .disabled(!bluetoothManager.isConnected)
                Toggle("Send Data", isOn: $dataToggle)
                    .disabled(!healthDataToggle && !weatherDataToggle)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: healthDataToggle) { newValue in
            if newValue {
                healthDataManager.requestAuthorization()
                
                if bluetoothManager.isConnected {
                    // Each thread independently grabs health data points.
                    healthDataManager.heartRateCompletion = { heart in
                        DispatchQueue.main.async {
                            print("Sending heart rate")
                            bluetoothManager.toSend.append((heart, ""))
                        }
                    }
                    healthDataManager.stepCountCompletion = { steps in
                        DispatchQueue.main.async {
                            print("Sending step count")
                            bluetoothManager.toSend.append((steps, ""))
                        }
                    }
                    healthDataManager.caloriesBurnedCompletion = { cals in
                        DispatchQueue.main.async {
                            print("Sending calories burned")
                            bluetoothManager.toSend.append((cals, ""))
                        }
                    }
                    healthDataManager.distanceCompletion = { dist in
                        DispatchQueue.main.async {
                            print("Sending distance running/walking")
                            bluetoothManager.toSend.append((dist, ""))
                        }
                    }
                    healthDataManager.alcoholCompletion = { alc in
                        DispatchQueue.main.async {
                            print("Sending number of alcoholic beverages")
                            bluetoothManager.toSend.append((alc, ""))
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
                        // Get weather data points when all the threads return.
                        await weatherDataManager.getWeather(latitude: locationDataManager.latitude, longitude: locationDataManager.longitude)
                        print("Temperature: \(weatherDataManager.temperature)")
                        print("Condition: \(weatherDataManager.condition)")
                        print("UV Index: \(weatherDataManager.uvIndex)")
                        print("Humidity: \(weatherDataManager.humidity)")
                        
                        if bluetoothManager.isConnected {
                            bluetoothManager.toSend.append(("TempF", String(weatherDataManager.temperature)))
                            bluetoothManager.toSend.append(("Condi", String(weatherDataManager.condition)))
                            bluetoothManager.toSend.append(("UVInd", String(weatherDataManager.uvIndex)))
                            bluetoothManager.toSend.append(("Humid", String(weatherDataManager.humidity)))
                        }
                    }
                }
            }
            else {
                locationDataManager.stopServices()
            }
        }
        
        .onChange(of: dataToggle) { newValue in
            if newValue {
                print("Toggle is ON.")
                
                // Send initial wave of data after 2 seconds.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    bluetoothManager.allCommands()
                    bluetoothManager.toSend.removeAll()
                    bluetoothManager.toSend.append(("Name", "\(userInput)"))
                }
                
                // Send any other data appended afterward every minute.
                send_timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { t in
                    print("This message fires every minute.")
                    bluetoothManager.allCommands()
                    bluetoothManager.toSend.removeAll()
                    bluetoothManager.toSend.append(("Name", "\(userInput)"))
                }
            }
            else {
                print("Toggle is OFF.")
                send_timer?.invalidate()
                send_timer = nil
            }
        }
        
        // Alert handling username edit.
        .alert("Change username", isPresented: $showingAlert) {
            TextField("Username", text: $newUsername)
                .textInputAutocapitalization(.words)
            Button("OK", action: saveEditedUsernameToKeychain)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enter a new username.")
        }
    }
    
    // Saves new username to Keychain, deleting the old username.
    private func saveEditedUsernameToKeychain() {
        let data = Data(newUsername.utf8)
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccount as String: "username"
        ] as CFDictionary

        let attributesToUpdate = [
            kSecValueData as String: data
        ] as CFDictionary

        let status = SecItemUpdate(query, attributesToUpdate)
        if status == errSecSuccess {
            print("Username updated successfully!")
            
            bluetoothManager.sendCommand(command: SendData(data: "Name: \(userInput)".data(using: .utf8)!))
            bluetoothManager.sendCommand(command: SendData(data: "NewName: \(newUsername)".data(using: .utf8)!))
            
            userInput = newUsername
        } else {
            print("Failed to update username.")
        }
    }
}

struct Preview : PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.light)
    }
}

