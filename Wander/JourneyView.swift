//
//  JourneyView.swift
//  Wander
//
//  Created by Dylan Elliott on 21/9/2022.
//

import SwiftUI
import CoreLocation
import MapKit
import AVFoundation

struct Location: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    
    var clLocationCoordinate: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D {
    var location: Location { .init(latitude: latitude, longitude: longitude) }
}

struct JourneyModel: Codable {
    let duration: TimeInterval
    let returnLocation: Location
    let startTime: Date
    let buffer: TimeInterval
}

class JourneyViewModel: NSObject, ObservableObject, Identifiable, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    enum State {
        case calculatingDirections
        case travelling
        case returning
        case late
    }
    var id: UUID = .init()
    private let duration: TimeInterval
    private let returnLocation: CLLocationCoordinate2D
    private let startTime: Date
    private let buffer: TimeInterval
    
    private var currentLocation: CLLocationCoordinate2D
    
    private var journeyDuration: TimeInterval {
        startTime.timeIntervalSinceNow
    }
    
    private var timeRemainingWithoutBuffer: TimeInterval {
        startTime.advanced(by: duration).timeIntervalSinceNow
    }
    private var timeRemaining: TimeInterval {
        timeRemainingWithoutBuffer.advanced(by: -buffer)
    }
    private var returnTime: TimeInterval?
    
    var titleText: String? {
        switch state {
        case .calculatingDirections: return nil
        case .travelling: return "Enjoy"
        case .returning: return "Time to Head Back"
        case .late: return "You're running late"
        }
    }
    
    var statusColour: Colors {
        switch state {
        case .calculatingDirections: return .yellow
        case .travelling: return .green
        case .returning: return .blue
        case .late: return .red
        }
    }
    
    @Published var journeyTimeText: String = ""
    @Published var timeRemainingText: String = ""
    @Published var timeToReturnText: String = ""
    @Published var state: State = .calculatingDirections
    var alarmTriggered: Bool = false
    
    var mapRegion: MKMapRect {
        MKCoordinateRegion(coordinates: mapPoints)?.mapRect ?? .init()
    }
    @Published var mapPoints: [CLLocationCoordinate2D]
    var mapLine: MKColouredPolyline {
        let line = MKColouredPolyline(coordinates: mapPoints, count: mapPoints.count)
        line.color = Colors.blue.uiColor
        return line
    }
    @Published var returnLine: MKPolyline?
    
    var timeFormatter: RelativeDateTimeFormatter = .init()
    lazy var locationManager: CLLocationManager = {
        let manager: CLLocationManager = .init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        return manager
    }()
    
    init(model: JourneyModel) {
        self.duration = model.duration
        self.returnLocation = model.returnLocation.clLocationCoordinate
        self.currentLocation = model.returnLocation.clLocationCoordinate
        self.startTime = model.startTime
        self.mapPoints = [model.returnLocation.clLocationCoordinate]
        self.buffer = model.buffer
        
        super.init()
        
        locationManager.startUpdatingLocation()
        UNUserNotificationCenter.current().delegate = self
        
        updateText()
        updateDirections()        
    }
    
    func updateDirections() {
        Task {
            do {
                let directionsRequest = MKDirections.Request()
                directionsRequest.source = currentLocation.mapItem
                directionsRequest.destination = returnLocation.mapItem
                directionsRequest.transportType = .walking
                
                let directions = MKDirections(request: directionsRequest)
                
                let response = try await directions.calculate()
                
                if let route = response.routes.first {
                    DispatchQueue.main.async {
                        self.returnTime = route.expectedTravelTime
                        self.returnLine = route.polyline
                        self.updateText()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + (600 / 400)) { [weak self] in
                    self?.updateDirections()
                }
            } catch {
                print("Error getting ETA: \(error)")
            }
        }
    }
    
    func updateText() {
        self.journeyTimeText = self.timeFormatter.localizedString(fromTimeInterval: self.journeyDuration).removingRelativeTimePrefixesAndSuffixes
        self.timeRemainingText = self.timeFormatter.localizedString(fromTimeInterval: self.timeRemaining)
        
        if let returnTime = self.returnTime {
            self.timeToReturnText = self.timeFormatter.localizedString(fromTimeInterval: returnTime).removingRelativeTimePrefixesAndSuffixes
            
            if returnTime < self.timeRemaining {
                self.state = .travelling
            } else if self.timeRemainingWithoutBuffer < returnTime {
                self.state = .late
                self.timeRemainingText = self.timeFormatter.localizedString(fromTimeInterval: self.timeRemainingWithoutBuffer)
            } else {
                self.state = .returning
            }
            
            if state == .returning || state == .late {
                triggerAlarm()
            }
        } else {
            self.timeToReturnText = "Calculating..."
            self.state = .calculatingDirections
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location.coordinate
        mapPoints.append(location.coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error updating location: \(error)")
    }
    
    func triggerAlarm() {
        guard alarmTriggered == false else { return }
        
        alarmTriggered = true
        
        NotificationHandler.shared.addNotification(
            id: UUID().uuidString,
            title: "Time to head back!",
            subtitle: "You have \(timeRemainingText.removingRelativeTimePrefixesAndSuffixes)",
            sound: .init(named: .init(rawValue: "DogBark.wav")),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        NotificationHandler.shared.addNotification(
            id: UUID().uuidString,
            title: "Time to head back!",
            subtitle: nil,
            sound: .init(named: .init(rawValue: "DogBark.wav")),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        )
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .badge, .banner, .list])
    }
}

struct JourneyView: View {
    @StateObject var viewModel: JourneyViewModel
    @State var mapTrackingMode: MapUserTrackingMode = .none
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MapView(
                    region: viewModel.mapRegion,
                    lines: [viewModel.mapLine, viewModel.returnLine].compactMap { $0 }
                )
                .disabled(true)
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    if let titleText = viewModel.titleText {
                        Text(titleText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(viewModel.statusColour.color)
                    }
                    
                    VStack {
                        Text("Total duration")
                        Text(viewModel.journeyTimeText)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("Need to be back")
                        Text(viewModel.timeRemainingText)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack {
                        Text("Time required to return")
                        Text(viewModel.timeToReturnText)
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
//                .cornerRadius(20)
            }
            VStack {
                HStack(alignment: .top) {
                    Spacer()
                    IconButton(imageName: "xmark") {
                        onCancel()
                    }
                }
                Spacer()
            }
        }
    }
}

struct JourneyView_Previews: PreviewProvider {
    static var previews: some View {
        JourneyView(
            viewModel: .init(model: .init(
                duration: 60,
                returnLocation: .init(latitude: 0, longitude: 0),
                startTime: .now,
                buffer: 5
            )),
            onCancel: {})
    }
}

extension CLLocationCoordinate2D {
    var mapItem: MKMapItem {
        .init(placemark: .init(coordinate: self))
    }
}

enum Colors {
    case blue
    case red
    case green
    case yellow
    
    var uiColor: UIColor {
        switch self {
        case .blue: return .init(hex: "#4361EE")
        case .red: return .init(hex: "#F95738")
        case .green: return .init(hex: "#29BF12")
        case .yellow: return .init(hex: "#FFD500")
        }
    }
    
    var color: Color {
        .init(self.uiColor)
    }
}

extension String {
    var removingRelativeTimePrefixesAndSuffixes: String {
        self.deletingPrefix("in ").deletingSuffix(" ago")
        
    }

    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}
