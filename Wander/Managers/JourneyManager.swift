//
//  JourneyManager.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

protocol JourneyManagerDelegate {
    func journeyManagerDidUpdate(userPath: MKPolyline)
    func journeyManagerDidUpdate(returnPath: MKPolyline)
    func journeyManagerDidUpdate(timeToReturn: TimeInterval)
    func journeyManagerDidEnterReturnMode()
}

class JourneyManager: LocationManagerDelegate {
    
    var delegate: JourneyManagerDelegate?
    
    private(set) var journey: Journey
    
    private var locationManager: LocationManager
    private(set) var locations: [CLLocationCoordinate2D] = []
    
    private var directionsCalculator: MKDirections?
    private var latestDirectionsResponse: NSObject?
    
    private var countdownTimer: Timer?
    
    private(set) var isInReturnMode: Bool = false
    
    var timeToReturn: TimeInterval? {
        switch latestDirectionsResponse {
        case let etaResponse as MKDirections.ETAResponse:
            return etaResponse.expectedTravelTime
        case let directionsResponse as MKDirections.Response:
            return directionsResponse.routes.first!.expectedTravelTime
        default:
            return nil
        }
    }
    
    var userPath: MKPolyline {
        return MKPolyline(coordinates: &locations, count: locations.count)
    }
    
    var returnPath: MKPolyline? {
        guard let directionsResponse = latestDirectionsResponse as? MKDirections.Response else { return nil }
        return directionsResponse.routes.first!.polyline
    }
    
    init(duration: TimeInterval, returnLocation: CLLocation) {
        self.journey = Journey(totalDuration: duration, returnLocation: returnLocation, startTime: nil)
        
        locationManager = LocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(didUpdate authorizationStatus: Bool) {
        // Can assume we already have authorization status
    }
    
    func locationManager(didUpdate location: CLLocation) {
        if journey.isStarted {
            locations.append(location.coordinate)
        }
        
        delegate?.journeyManagerDidUpdate(userPath: userPath)
        
        initiateLocationCalculation()
    }
    
    func startJourney() {
        journey.start()
    }
    
    func initiateLocationCalculation() {
        if directionsCalculator == nil {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location!.coordinate)) // Possible crash
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: journey.returnLocation.coordinate))
            request.transportType = .walking
            
            directionsCalculator = MKDirections(request: request)
            
            if isInReturnMode == false {
                directionsCalculator!.calculateETA(completionHandler: didCalculateDirections)
            } else {
                directionsCalculator!.calculate(completionHandler: didCalculateDirections)
            }
        }
    }
    
    func didCalculateDirections(response: NSObject?, error: Error?) {
        directionsCalculator = nil
        
        guard let response = response else { return }
        latestDirectionsResponse = response
        
        delegate?.journeyManagerDidUpdate(timeToReturn: timeToReturn!)
        
        if let etaResponse = response as? MKDirections.ETAResponse {
            if journey.isTimeToTurnBack(travelTime: etaResponse.expectedTravelTime) {
                startReturnMode()
            }
        } else if let _ = response as? MKDirections.Response {
            delegate?.journeyManagerDidUpdate(returnPath: returnPath!)
        }
    }
    
    func startReturnMode() {
        guard isInReturnMode == false else { return }
        
        isInReturnMode = true
        delegate?.journeyManagerDidEnterReturnMode()
    }
}
