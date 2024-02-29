//
//  HealthData.swift
//  ISM App
//

import Foundation
import HealthKit

class HealthDataManager {
    let healthStore = HKHealthStore()
    
    enum HealthDataType {
        case stepCount
        case exerciseTime
        case moveTime
        case standTime
        case activeEnergyBurned
    }
    
    // Request authorization from user to get Health app data.
    func requestAuthorization() {
        // Data to read from health app.
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.quantityType(forIdentifier: .appleMoveTime)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        // Request authorization and send message based on answer.
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("HealthKit authorization granted.")
            }
            else {
                print("HealthKit authorization denied.")
            }
        }
    }
    
    // Fetch data for specific type.
    func fetchData(for type: HealthDataType) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available.")
            return
        }
        
        var sampleType: HKQuantityType?
        
        // Get specified health type.
        switch type {
        case .stepCount:
            sampleType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        case .exerciseTime:
            sampleType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        case .moveTime:
            sampleType = HKObjectType.quantityType(forIdentifier: .appleMoveTime)!
        case .standTime:
            sampleType = HKObjectType.quantityType(forIdentifier: .appleStandTime)!
        case .activeEnergyBurned:
            sampleType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        }
        
        // Make sure sample type is valid.
        guard let unwrappedSampleType = sampleType else {
            print("Invalid health data type entered.")
            return
        }
        
        // Get health data.
        let query = HKSampleQuery(sampleType: unwrappedSampleType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("Error fetching steps data: \\(error!.localizedDescription)")
                return
            }
            
            // Debug: remove later?
            for sample in results {
                let value = sample.quantity.doubleValue(for: .count())
                print("Steps: \\(value")
            }
            
        }
    }
}
