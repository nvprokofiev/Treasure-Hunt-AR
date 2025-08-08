//
//  LocationManager.swift
//  ar
//
//  Created by Nikolai Prokofev on 2024-08-05.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var continuation: AsyncStream<CLLocation>.Continuation?
    
    var locationStream: AsyncStream<CLLocation>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        
        locationStream = AsyncStream { continuation in
            self.continuation = continuation
        }
        
        // Request authorization
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        print("LocationManager: Requesting location permission")
        switch locationManager.authorizationStatus {
        case .notDetermined:
            print("LocationManager: Authorization not determined, requesting permission")
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Authorization granted, starting location updates")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        @unknown default:
            break
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("LocationManager: Received \(locations.count) locations")
        for location in locations {
            print("LocationManager: Accuracy: \(location.horizontalAccuracy)m")
            if location.horizontalAccuracy <= 20 { // Increased threshold to 100 meters
                print("LocationManager: Yielding location with accuracy \(location.horizontalAccuracy)m")
                continuation?.yield(location)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("LocationManager: Authorization status changed to: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("LocationManager: Starting location updates after authorization")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}
