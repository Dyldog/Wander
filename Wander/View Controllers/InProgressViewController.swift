//
//  InProgressViewController.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class InProgressViewController: UIViewController, MKMapViewDelegate, JourneyManagerDelegate {
    
    enum MapOverlays {
        enum PreviousPathLine {
            static let title = "Previous Path"
        }
        
        enum ReturnPathLine {
            static let title = "Return Path"
        }
    }
    
    @IBOutlet var countdownLabel: UILabel!
    @IBOutlet var etaLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    
    var totalDuration: TimeInterval!
    var returnLocation: CLLocation!
    var journeyManager: JourneyManager!
    
    var countdownTimer: Timer?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        countdownLabel.text = totalDuration.clockString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startJourney()
    }
    
    func startJourney() {
        journeyManager = JourneyManager(duration: totalDuration, returnLocation: returnLocation)
        journeyManager.delegate = self
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: countdownTimerDidFire)
        
        journeyManager.startJourney()
    }
    
    // MARK: Timer
    
    func countdownTimerDidFire(timer: Timer) {
        refreshLabels()
    }
    
    // MARK: UI Updating
    
    func refreshPathOverlays() {
        mapView.removeOverlays(mapView.overlays)
        
        let previousPath = journeyManager.userPath
        previousPath.title = MapOverlays.PreviousPathLine.title
        mapView.addOverlay(previousPath, level: .aboveLabels)
        
        if let returnPath = journeyManager.returnPath {
            returnPath.title = MapOverlays.ReturnPathLine.title
            mapView.addOverlay(returnPath, level: .aboveLabels)
        }
    }
    
    func refreshLabels() {
        countdownLabel.text = journeyManager.journey.timeRemaining?.clockString ?? "Starting journey..."
        etaLabel.text = journeyManager.timeToReturn?.clockString ?? "Calculating travel time..."
        
    }
    
    // MARK: Map UI
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        polylineRenderer.strokeColor = overlay.title == MapOverlays.ReturnPathLine.title ? .red : .blue
        polylineRenderer.lineWidth = 5
        return polylineRenderer
    }
    
    func zoomToLocation(_ location: CLLocationCoordinate2D) {
        mapView.setCamera(MKMapCamera(lookingAtCenter: location, fromEyeCoordinate: location, eyeAltitude: 1000.0), animated: true)
    }
    
    func showReturnAlert() {
        let center = UNUserNotificationCenter.current()
        
        let notification = UNMutableNotificationContent()
        notification.title = "Time to head back"
        notification.body = "It will take you \(journeyManager.timeToReturn!.clockString)"
        notification.sound = UNNotificationSound.defaultCritical
        notification.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber;

        let nowTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let nowRequest = UNNotificationRequest(identifier: "RETURN_MODE_NOTIF_NOW", content: notification, trigger: nowTrigger)
        center.add(nowRequest)
        
        let futureTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        let futureRequest = UNNotificationRequest(identifier: "RETURN_MODE_NOTIF_FUTURE", content: notification, trigger: futureTrigger)
        center.add(futureRequest)
        
        
//        let alert = UIAlertController(title: "Time to head back", message: "It will take you \(timeToReturn!.clockString)", preferredStyle: .alert) // Possible crash
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
    }
    
    func journeyManagerDidUpdate(userPath: MKPolyline) {
        if journeyManager.locations.count == 1 {
            zoomToLocation(journeyManager.locations[0])
        }
        
        refreshPathOverlays()
    }
    
    func journeyManagerDidUpdate(returnPath: MKPolyline) {
        refreshPathOverlays()
    }
    
    func journeyManagerDidUpdate(timeToReturn: TimeInterval) {
        refreshLabels()
    }
    
    func journeyManagerDidEnterReturnMode() {
        showReturnAlert()
    }
}
