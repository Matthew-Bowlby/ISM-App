//
//  HealthData.swift
//  ISM App
//

import HealthKit

class HealthDataManager : ObservableObject {
    let healthStore = HKHealthStore()
    var fetching: Bool = false
    var lastHeartRateValue: Double? = nil
    var query: HKQuery?
    
    // Data to read from health app.
    let typesToRead: Set = [
        HKQuantityType(.stepCount),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.distanceWalkingRunning)
    ]
    
    // Sends completion string upon thread returning.
    typealias Completion = (String) -> Void
    var heartRateCompletion: Completion?
    var stepCountCompletion: Completion?
    var caloriesBurnedCompletion: Completion?
    var distanceCompletion: Completion?
    var alcoholCompletion: Completion?
    
    // Requests authorization from user to grab data.
    func requestAuthorization() {
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("HealthKit authorization granted.")
                self.fetchData()
            }
            else {
                print("HealthKit authorization denied.")
            }
        }
    }
    
    // Stops fetching health data.
    func stopFetchData() {
        if let query = query {
            healthStore.stop(query)
        }
    }
    
    // Fetch data for specific type.
    func fetchData() {
        self.fetching = true
        
        for dataType in typesToRead {
            query = HKObserverQuery(sampleType: dataType, predicate: nil) { query, completionHandler, error in
                    if let error = error {
                        print(" *** Error while observing changes: \(error.localizedDescription) ***")
                        completionHandler()
                        return
                    }
                switch dataType.identifier {
                case HKQuantityTypeIdentifier.heartRate.rawValue:
                    self.fetchLatestHeartRateData() { str in
                        self.heartRateCompletion?(str)
                    }
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    self.fetchLatestDailyData(for: dataType) { str in
                        self.stepCountCompletion?(str)
                    }
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    self.fetchLatestDailyData(for: dataType) { str in
                        self.caloriesBurnedCompletion?(str)
                    }
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    self.fetchLatestDailyData(for: dataType) { str in
                        self.distanceCompletion?(str)
                    }
                case HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue:
                    self.fetchLatestDailyData(for: dataType) { str in
                        self.alcoholCompletion?(str)
                    }
                default:
                    break
                }
            }
            healthStore.execute(query!)
            healthStore.enableBackgroundDelivery(for: dataType, frequency: HKUpdateFrequency.immediate, withCompletion: { (success, error) in
                if let unwrappedError = error {
                    print("*** Error: could not enable background delivery: \(unwrappedError) ***")
                }
                if success {
                    print("Background delivery enabled for \(dataType.identifier)")
                }
            })
        }
    }
    
    // Handles heart rate specifically. Only parameter that is an anchored object query.
    func fetchLatestHeartRateData(completion: @escaping (String) -> Void) {
        var anchor: HKQueryAnchor?
        
        let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate)
        let anchoredQuery = HKAnchoredObjectQuery(type: sampleType!, predicate: nil, anchor: anchor, limit: HKObjectQueryNoLimit) { query, newSamples, deletedSamples, newAnchor, error in
            if let error = error {
                print("*** Error while executing anchored query: \(error.localizedDescription) ***")
                return
            }

            guard let newSamples = newSamples as? [HKQuantitySample], let sample = newSamples.last else {
                print("*** Error: No heart rate samples found ***")
                return
            }
            
            anchor = newAnchor
            
            let heartRateValue = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            let str = "Heart: \(heartRateValue)"
            print("Heart Rate: \(heartRateValue)")
            completion(str)
        }

        healthStore.execute(anchoredQuery)
    }
    
    // Handles other statistical data points.
    func fetchLatestDailyData(for sampleType: HKQuantityType, completion: @escaping (String) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let statsQuery = HKStatisticsQuery(quantityType: sampleType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (statsQuery, result, error) in
            if let error = error {
                print("*** Error fetching daily data for \(sampleType.identifier): \(error.localizedDescription) ***")
            }
            
            if let result = result, let sum = result.sumQuantity() {
                switch sampleType.identifier {
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    let unit = HKUnit.kilocalorie()
                    let daily = String(format: "%.2f", sum.doubleValue(for: unit))
                    let str = "CaloB: \(daily)"
                    print("Calories Burned: \(daily)")
                    completion(str)

                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    let unit = HKUnit.count()
                    let daily = String(format: "%.2f", sum.doubleValue(for: unit))
                    let str = "StepC: \(daily)"
                    print("Step Count: \(daily)")
                    completion(str)
                    
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    let unit = HKUnit.mile()
                    let daily = String(format: "%.2f", sum.doubleValue(for: unit))
                    let str = "DistW: \(daily)"
                    print("Distance Walking/Running: \(daily)")
                    completion(str)
                
                case HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue:
                    let unit = HKUnit.count()
                    let daily = String(format: "%.2f", sum.doubleValue(for: unit))
                    let str = "AlcoB: \(daily)"
                    print("Number of Alcoholic Beverages: \(daily)")
                    completion(str)
                
                default:
                    print("Unrecognized daily value: \(sampleType.identifier)")
                }
            }
            else {
                print("No data available for \(sampleType.identifier)")
                
                switch sampleType.identifier {
                case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
                    completion("CaloB: 0.0")
                    
                case HKQuantityTypeIdentifier.stepCount.rawValue:
                    completion("StepC: 0")
                 
                case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
                    completion("DistW: 0")
                
                case HKQuantityTypeIdentifier.numberOfAlcoholicBeverages.rawValue:
                    completion("AlcoB: 0")
                    
                default:
                    print("Unrecognized daily value: \(sampleType.identifier)")
                }
            }
        }
        healthStore.execute(statsQuery)
    }
}
