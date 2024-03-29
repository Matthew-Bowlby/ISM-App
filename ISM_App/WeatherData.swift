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
    
    var temperature: String {
        let temp = weather?.currentWeather.temperature
        let convert = temp?.converted(to: .fahrenheit).description
        
        return convert ?? "Loading Weather Data"
    }
    
    var condition: String {
        return weather?.currentWeather.condition.rawValue ?? "Loading Weather Data"
    }
}
