//
//  ContentView.swift
//  Wander
//
//  Created by Dylan Elliott on 21/9/2022.
//

import SwiftUI
import CoreLocation

class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @UserDefaultable(key: .defaultDuration) var defaultDuration: Int = 60
    @Published var totalMinutes: Int = 30 /* In minutes */ { didSet { defaultDuration = totalMinutes}}
    
    @UserDefaultable(key: .defaultBuffer) var defaultBuffer: Int = 5
    @Published var bufferMinutes: Int = 30 /* In minutes */ { didSet { defaultBuffer = bufferMinutes }}
    
    var totalTime: TimeInterval { TimeInterval(totalMinutes * 60) }
    var bufferTime: TimeInterval { TimeInterval(bufferMinutes * 60) }
    
    @Published private var startLocation: CLLocation? {
        didSet { unableToStartMessage = nil }
    }
    @Published var journeyViewModel: JourneyViewModel?
    @UserDefaultable(key: .lastJourney) private var lastJourney: JourneyModel? = nil
    var hasLastJourney: Bool { lastJourney != nil }
    
    lazy private var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    private var notificationManager: NotificationHandler = .shared
    
    override init() {
        super.init()
        getLocation()
        totalMinutes = defaultDuration
        bufferMinutes = defaultBuffer
    }
    
    var unableToStartMessage: String? = "Waiting for current location"
    
    var pickerItems: [(Int, String)] = (1 ... (120 / 15)).map {
        let minutes = $0 * 15
        return (minutes, "\(minutes) minutes")
    }
    
    var bufferPickerItems: [(Int, String)] = (0 ... 60).map {
        let minutes = $0
        return (minutes, "\(minutes) minutes")
    }
    
    private func getLocation() {
        locationManager.requestLocation()
        locationManager.startUpdatingLocation()
    }
    
    func start() {
        guard let startLocation = startLocation else { return }
        let model = JourneyModel(
            duration: totalTime,
            returnLocation: startLocation.coordinate.location,
            startTime: .now,
            buffer: bufferTime
        )
        lastJourney = model
        journeyViewModel = .init(model: model)
    }
    
    func startLastJourney() {
        guard let lastJourney = lastJourney else { return }
        journeyViewModel = .init(model: lastJourney)
    }
    
    func didAppear() {
        locationManager.requestAlwaysAuthorization()
        notificationManager.requestPermission()
        NotificationHandler.shared.removeAllNotifications()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        getLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard journeyViewModel == nil else { return }
        // TODO: Is `last` the right location to choose?
        startLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO: Error handling
        print("Failed to get location: \(error)")
    }
}
struct ContentView: View {
    
    @StateObject var viewModel: ContentViewModel = .init()
    
    var body: some View {
        VStack {
            Rectangle().frame(height: 200).foregroundColor(.clear)
            
            Text("Going for a wander?")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack {
//                Text("Total time")
//                    .fontWeight(.bold)
                Picker(
                    "Total time",
                    selection: $viewModel.totalMinutes,
                    content: {
                        ForEach(viewModel.pickerItems, id: \.0) {
                            Text($0.1).tag($0.0)
                        }
                    }
                )
                .pickerStyle(WheelPickerStyle())
            }
            
            HStack {
                Text("Buffer")
                
                Picker("Buffer", selection: $viewModel.bufferMinutes) {
                    ForEach(viewModel.bufferPickerItems, id: \.0) {
                        Text($0.1).tag($0.0)
                    }
                }
            }
            
            
            
            if let message = viewModel.unableToStartMessage {
                Text(message).foregroundColor(.red)
            } else {
                Button("Start") {
                    viewModel.start()
                }
                .font(.largeTitle)
                .padding()
            }
            
            Spacer()
            
            if viewModel.hasLastJourney {
                Button("Start Last Journey") {
                    viewModel.startLastJourney()
                }
                .font(.footnote)
                .padding(.top, 30)
            }
        }
        .onAppear {
            viewModel.didAppear()
        }
        .fullScreenCover(item: $viewModel.journeyViewModel) {
            JourneyView(viewModel: $0, onCancel: { viewModel.journeyViewModel = nil })
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension Int: Identifiable {
    public var id: Int { self }
}
