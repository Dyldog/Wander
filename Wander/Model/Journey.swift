//
//  Journey.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import Foundation
import CoreLocation

struct Journey {
    let totalDuration: TimeInterval
    let returnLocation: CLLocation
    private(set) var startTime: NSDate? = nil
    
    var endTime: NSDate? {
        return startTime?.addingTimeInterval(totalDuration)
    }
    
    var timeRemaining: TimeInterval? {
        return endTime?.timeIntervalSinceNow
    }
    
    var isStarted: Bool {
        return startTime != nil
    }
    
    func isTimeToTurnBack(travelTime: TimeInterval) -> Bool {
        guard let timeRemaining = timeRemaining else { return false }
        let timeRemainingIncludingJourney = timeRemaining - travelTime
        return timeRemainingIncludingJourney <= Constants.minimumSpareTime
    }
    
    enum Constants {
        static let minimumSpareTime: TimeInterval = 3 * 60
    }
    
    mutating func start() {
        startTime = NSDate()
    }
}
