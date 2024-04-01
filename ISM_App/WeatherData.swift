//
//  WeatherData.swift
//  ISM_App
//

import WeatherKit

class WeatherDataManager {
    var weather: Weather?
    
    func getWeather(latitude: Double, longitude: Double) async {
        do {
            weather = try await Task.detached(priority: .userInitiated) {
                return try await WeatherService.shared.weather(for: .init(latitude: latitude, longitude: longitude))
            }.value
        } catch {
            print("*** Error: \(error) ***")
        }
    }
    
    var temperature: Int {
        let temp = weather?.currentWeather.temperature
        let convert = Int(temp?.converted(to: .fahrenheit).value ?? 0)
        
        return convert
    }
    
    var condition: String {
        return weather?.currentWeather.condition.rawValue ?? "n/a"
    }
    
    var uvIndex: Int {
        return weather?.currentWeather.uvIndex.value ?? 0
    }
    
    var humidity: Int {
        return Int((weather?.currentWeather.humidity ?? 0) * 100)
    }
}
