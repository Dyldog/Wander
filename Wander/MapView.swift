//
//  MapView.swift
//  Wander
//
//  Created by Dylan Elliott on 22/9/2022.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    
    let region: MKMapRect
    let lines: [MKPolyline]
    let padding: UIEdgeInsets = .init(top: 50, left: 50, bottom: 50, right: 50)
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        lines.forEach {
            mapView.addOverlay($0)
        }
        
        mapView.setVisibleMapRect(
            region,
            edgePadding: padding,
            animated: false
        )
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        view.removeOverlays(view.overlays)
        lines.forEach {
            view.addOverlay($0)
        }
        
        view.setVisibleMapRect(
            region,
            edgePadding: padding,
            animated: false
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}

class Coordinator: NSObject, MKMapViewDelegate {
    var parent: MapView
    
    init(_ parent: MapView) {
        self.parent = parent
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let routePolyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: routePolyline)
            renderer.strokeColor = (routePolyline as? MKColouredPolyline)?.color ?? Colors.red.uiColor
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
}

class MKColouredPolyline: MKPolyline {
    var color: UIColor?
}
