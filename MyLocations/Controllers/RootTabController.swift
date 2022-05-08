
import UIKit
import CoreLocation

class RootTabController: UITabBarController, UITabBarControllerDelegate {
  
  let geolocation = Geolocation.shared
  var previousTabIndex: Int = 0
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.delegate = self
    geolocation.locationManager.delegate = self
  }
  
  // MARK: TabBar Controller Delegate
  func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
    previousTabIndex = self.selectedIndex
    
    let selectedViewController = (viewController as! UINavigationController).viewControllers.first!
    if selectedViewController is MapViewController {
      let authStatus = geolocation.locationManager.authorizationStatus
      if authStatus == .notDetermined {
        geolocation.locationManager.requestWhenInUseAuthorization()
      } else if authStatus == .denied || authStatus == .restricted {
        listenForLocationServiceDeniedNotification(self)
        locationServiceDenied()
        return false
      }
    }
    return true
  }
  
}


extension RootTabController: CLLocationManagerDelegate {
  // MARK: Location Manager Delegate
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let currentTab = (self.viewControllers?[selectedIndex] as! UINavigationController).viewControllers.first
    if (currentTab is MapViewController) &&
        (manager.authorizationStatus == .denied || manager.authorizationStatus  == .restricted) {
      listenForLocationServiceDeniedNotification(self)
      locationServiceDenied()
      self.selectedIndex = previousTabIndex
    }
  }
}
