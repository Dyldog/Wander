//
//  Extensions.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import Foundation

extension TimeInterval {
    var clockString: String {
        let oneHour: Double = 60 * 60
        let hours = Int(floor(self / oneHour))
        let minutes = Int(floor((self - Double(hours) * oneHour) / 60.0))
        let unpaddedMinutesString = "\(minutes)"
        let minutesString = unpaddedMinutesString.count == 1 ? "0\(unpaddedMinutesString)" : unpaddedMinutesString
        let seconds = Int(self) - hours * Int(oneHour) - minutes * 60
        let unpaddedSecondsString = "\(seconds)"
        let secondsString = unpaddedSecondsString.count == 1 ? "0\(unpaddedSecondsString)" : unpaddedSecondsString
        
        return "\(hours):\(minutesString):\(secondsString)"
    }
}
