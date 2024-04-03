//
//  CalendarData.swift
//  ISM_App
//
//  Created by M on 4/1/24.
//

import Foundation
import EventKit
import EventKitUI
import UIKit
//import EKEventStore

class EventDataManager: ObservableObject {
    
    let store = EKEventStore()
    var sortedEvents:NSArray = []
    var fetching: Bool = false
    //var authorization: Bool = false
    
    func requestAccess() {
        store.requestFullAccessToEvents { granted, error in
            if granted && error == nil {
                //self.authorization = true
                print("EventKit authorization granted.")
                self.fetchEvents()
            } else {
                //self.authorization = false
                print("HealthKit authorization denied.")
            }
        }
    }
    
    func fetchEvents() {
        
        // Create a predicate
        guard let interval = Calendar.current.dateInterval(of: .month, for: Date()) else { return }
        let predicate = store.predicateForEvents(withStart: interval.start,
                                             end: interval.end,
                                             calendars: nil)
    
        // Fetch the events
        let events = store.events(matching: predicate)
    
        sortedEvents = events.sorted { $0.compareStartDate(with: $1) == .orderedAscending } as NSArray
        
    }
    
    
    /*func fetchEvents() async {
        // Create an event store
        //let store = EKEventStore()
    
        // Request full access
        do{
            try await authorization = store.requestFullAccessToEvents()// else { return }     true
        }
        catch{
            print("*** Error: \(error) ***") //false
        }
        //guard try await store.requestFullAccessToEvents() else { return }
    
        // Create a predicate
        guard let interval = Calendar.current.dateInterval(of: .month, for: Date()) else { return }
        let predicate = store.predicateForEvents(withStart: interval.start,
                                             end: interval.end,
                                             calendars: nil)
    
        // Fetch the events
        let events = store.events(matching: predicate)
    
        let sortedEvents = events.sorted { $0.compareStartDate(with: $1) == .orderedAscending }
    }*/
    
    
}
