//
//  StartViewController.swift
//  Wander
//
//  Created by Dylan Elliott on 16/9/18.
//  Copyright © 2018 Dylan Elliott. All rights reserved.
//

import UIKit
import CoreLocation

class StartViewController: UIViewController, LocationManagerDelegate {
    
    enum Segue {
        static var startJourney = "START_JOURNEY"
    }
    
    @IBOutlet var durationPicker: UIDatePicker!
    @IBOutlet var startButton: UIButton!
    
    var locationManager: LocationManager!
    
    
    
    func commonInit() {
        locationManager = LocationManager()
        locationManager.delegate = self
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        durationPicker.countDownDuration = 60*60;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        locationManager.requestLocationPermission()
    }
    
    func startJourney() {
        guard locationManager.location != nil else {
            print("ERROR: Don't have location when starting journey")
            return
        }
        
        performSegue(withIdentifier: Segue.startJourney, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case Segue.startJourney:
            guard let returnLocation = locationManager.location else {
                print("ERROR: Don't have location when preparing for start journey segue")
                break
            }
            
            let inProgressVC = segue.destination as! InProgressViewController // Possible Crash
            inProgressVC.totalDuration = durationPicker.countDownDuration
            inProgressVC.returnLocation = returnLocation
            
        default:
            break
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func startButtonTapped() {
        startJourney()
    }
    
    // MARK: - LocationManagerDelegate
    
    func locationManager(didUpdate authorizationStatus: Bool) {
        if authorizationStatus == true {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestLocationPermission()
        }
    }
    
    func locationManager(didUpdate location: CLLocation) {
        startButton.isEnabled = true
    }
}
