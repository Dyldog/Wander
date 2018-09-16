//
//  LocationManager.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import CoreLocation

protocol LocationManagerDelegate {
    func locationManager(didUpdate authorizationStatus: Bool)
    func locationManager(didUpdate location: CLLocation)
}

class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private lazy var locationProvider: CLLocationManager = {
        let locationManager = CLLocationManager()
        locationManager.delegate = self
        return locationManager
    }()
    
    var delegate: LocationManagerDelegate?
    
    var location: CLLocation?
    
    var locationPermissionGranted: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways
    }
    
    func requestLocationPermission() {
        locationProvider.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationProvider.allowsBackgroundLocationUpdates = true
        locationProvider.pausesLocationUpdatesAutomatically = false
        locationProvider.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        delegate?.locationManager(didUpdate: status == .authorizedAlways)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let newLocation = manager.location {
            location = newLocation
            delegate?.locationManager(didUpdate: newLocation)
        }
    }
}
