//
//  ViewController.swift
//  Wander
//
//  Created by Dylan Elliott on 15/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class DebugMapViewController: UIViewController, LocationManagerDelegate, MKMapViewDelegate {

    var locationManager = LocationManager()
    
    var locations: [CLLocationCoordinate2D] = []
    
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startLocationUpdates()
    }

    func startLocationUpdates() {
        locationManager.delegate = self
        
        if locationManager.locationPermissionGranted == false {
            locationManager.requestLocationPermission()
        } else {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(didUpdate authorizationStatus: Bool) {
        startLocationUpdates()
    }
    
    func locationManager(didUpdate location: CLLocation) {
        locations.append(location.coordinate)
        
        if locations.count == 1 {
           let firstLocation = locations[0]
            mapView.setCamera(MKMapCamera(lookingAtCenter: firstLocation, fromEyeCoordinate: firstLocation, eyeAltitude: 1000.0), animated: true)
        }
        
        let line = MKPolyline(coordinates: &locations, count: locations.count)
        
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(line, level: .aboveLabels)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = UIColor.blue
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
}

