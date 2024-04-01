//
//  LocationData.swift
//  ISM_App
//

import CoreLocation

class LocationDataManager : NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    @Published var authorization: CLAuthorizationStatus?
    @Published var status: Bool = false
    
    var latitude: Double {
        locationManager?.location?.coordinate.latitude ?? 0.0
    }
    
    var longitude: Double {
        locationManager?.location?.coordinate.longitude ?? 0.0
    }
    
    override init() {
        super.init()
        startServices()
    }
    
    func startServices() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        status = true
    }
    
    func stopServices() {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            authorization = .authorizedWhenInUse
            locationManager?.startUpdatingLocation()
            break
        case .restricted:
            authorization = .restricted
            break
            
        case .denied:
            authorization = .denied
            break
            
        case .notDetermined:
            authorization = .notDetermined
            manager.requestWhenInUseAuthorization()
            break
            
        default:
            break
        }
    }
    
    /*
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude)")
        }
    }
    */
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("*** Error: Location update error: \(error.localizedDescription) ***")
    }
}
