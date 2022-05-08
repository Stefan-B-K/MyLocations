
import CoreLocation

class Geolocation {
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updating = false
  var lastError: Error?
  var timer: Timer?
  
  var caller: CLLocationManagerDelegate!
  
  static let shared: Geolocation = {
    return Geolocation()
  }()
  
  
  private init() {}
  
  func getLocation() {
    let authStatus = locationManager.authorizationStatus
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
    } else if authStatus == .denied || authStatus == .restricted {
      locationServiceDenied()
      return
    }
    location = nil; lastError = nil
    startLocationManager()
  }
  
  private func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = caller!
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updating = true
      timer = Timer.scheduledTimer(timeInterval: 15, target: self,
                                   selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  @objc private func didTimeOut() {
    if location == nil {
      lastError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
    }
    stopLocationManager()
    (caller as! CurrentLocationViewController).updateLabels()
  }
  
  func stopLocationManager() {
    if updating {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updating = false
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  func updateLocations(_ locations: [CLLocation]) {
    let newLocation = locations.last!
    
    guard newLocation.timestamp.timeIntervalSinceNow >= -5 else { return }      // > 5 seconds old result   -->   cached result
    guard newLocation.horizontalAccuracy >= 0 else { return }                   // < 0  -->   invalid result
    
    var resultsDistance = CLLocationDistance(Double.greatestFiniteMagnitude)    // resultsDistance  --> за устройства без нужната точност (10 метра) ! ! !
    if let location = location {
      resultsDistance = newLocation.distance(from: location)
    }
    
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {     // if first result  OR  more accurate one
      lastError = nil
      location = newLocation
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        stopLocationManager()
      }
    } else if resultsDistance < 1 {                               // if small distance between results and > 10 secs from the result   -->   STOP
      let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
      if timeInterval > 10 {
        stopLocationManager()
      }
    }
  }
  
}

extension Geolocation: NSCopying {                  // disable copying
    func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}

