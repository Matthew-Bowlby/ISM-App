//
//  HealthData.swift
//  ISM App
//

import Foundation
import HealthKit

class HealthDataManager {
    let healthStore = HKHealthStore()
    var authorization: Bool = false
    
    // Data to read from health app.
    let typesToRead: Set = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate)
    ]
    
    // Fetch data for specific type.
    func fetchData() {
        for dataType in typesToRead {
            healthStore.enableBackgroundDelivery(for: dataType, frequency: HKUpdateFrequency.immediate, withCompletion: { (success, error) in
                if let unwrappedError = error {
                    print("*** Error: could not enable background delivery: \(unwrappedError) ***")
                }
                if success {
                    print("Background delivery enabled")
                }
            })
                
            let query = HKObserverQuery(sampleType: dataType, predicate: nil) { query, completionHandler, error in
                    if let error = error {
                        print(" *** Error while observing changes: \(error.localizedDescription) ***")
                        completionHandler()
                        return
                    }
                    self.fetchLatestData(for: dataType)
                    completionHandler()
                }
                
                healthStore.execute(query)
                                                 }
    }
    
    func fetchLatestData(for sampleType: HKSampleType) {
        switch sampleType.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            // Handle heart rate data
            fetchLatestHeartRateData { result in
                switch result {
                case .success(let heartRate):
                    print("Latest heart rate: \(heartRate) bpm")
                case .failure(let error):
                    print("Error fetching heart rate: \(error.localizedDescription)")
                }
            }
            /*
        case HKQuantityTypeIdentifier.stepCount.rawValue:
            // Handle step count data
            fetchLatestStepCountData { result in
                switch result {
                case .success(let stepCount):
                    print("Latest step count: \(stepCount) steps")
                case .failure(let error):
                    print("Error fetching step count: \(error.localizedDescription)")
                }
            }
             */
        default:
            break
        }
    }
    
    func fetchLatestHeartRateData(completion: @escaping (Result<Double, Error>) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, samples, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(.failure(NSError(domain: "YourAppErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: "No heart rate data available"])))
                return
            }
            
            let heartRateValue = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            completion(.success(heartRateValue))
        }
        
        healthStore.execute(query)
    }
    
    /*
    func transmitHealthData(_ value: Double, for type: HealthDataType) {
        let data = "\(type): \(value)".data(using: .utf8)!
        let command = SendData(data: data)
        
            //bluetoothManager.sendCommand(command: command)
    }
     */
}
