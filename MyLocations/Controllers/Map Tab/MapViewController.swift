
import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  
  let geolocation = Geolocation.shared
  var locations = [Location]()
  var selectedPin: CLLocationCoordinate2D?                        // to re-select after editing location --> updateLocations()
  var managedObjectContext: NSManagedObjectContext! {
    didSet {
      NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange,
                                             object: managedObjectContext, queue: OperationQueue.main) { [weak self] notification in
        if let weakSelf = self, weakSelf.isViewLoaded {
          weakSelf.updateChangedLocation(for: notification)           // update on change in locations ONLY if current TAB view is loaded (switched to)
        }
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    loadLocations()
    if !locations.isEmpty {
      showAllLocations()
    }
  }
  
  @IBAction func zoomToUserLocation() {
    let region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
    mapView.setRegion(mapView.regionThatFits(region), animated: true)
  }
  
  @IBAction func showAllLocations() {
    let locationsRegion = region(for: locations)
    mapView.setRegion(locationsRegion, animated: true)
  }
  
  // MARK: - Helper methods
  
  func loadLocations() {
    let fetchRequest = Location.fetchRequest()
    locations = try! managedObjectContext.fetch(fetchRequest)
    mapView.addAnnotations(locations)
  }
  
  func updateChangedLocation(for notification: Notification) {
    
    if let insertedLocations = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
      let locationToInsert = insertedLocations.first! as! Location
      locations.append(locationToInsert)
      mapView.addAnnotation(locationToInsert)
    }
    
    if let deletedLocations = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> {
      let locationToDelete = deletedLocations.first! as! Location
      let indexToRemove = locations.firstIndex(of: locationToDelete)!
      locations.remove(at: indexToRemove)
      mapView.removeAnnotation(locationToDelete)
    }
    
    if let updatedLocations = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
      let locationToUpdate = updatedLocations.first! as! Location
      let indexToUpdate = locations.firstIndex(of: locationToUpdate)!
      mapView.removeAnnotation(locations[indexToUpdate])
      mapView.addAnnotation(locationToUpdate)
      locations[indexToUpdate] = locationToUpdate
    }
    
    if let selectedPin = selectedPin {                              // to re-select after editing location
      let index = mapView.annotations.firstIndex { ($0.coordinate == selectedPin) && $0 is Location }
      let selectedAnotation = mapView.annotations[index!]
      mapView.selectAnnotation(selectedAnotation, animated: false)
    }
  }
  
  func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
    let region: MKCoordinateRegion
    
    switch annotations.count {
    case 0:
      region = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
      
    case 1:
      let annotation = annotations[annotations.count - 1]
      region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
      
    default:
      var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
      var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
      
      for annotation in annotations {
        topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
        topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
        bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
        bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
      }
      
      let center = CLLocationCoordinate2D(
        latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude) / 2,
        longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude) / 2)
      
      if ((topLeft.latitude - bottomRight.latitude) * 111_139 < 100) && ((topLeft.longitude - bottomRight.longitude) * 111_139 < 100) {
        region = MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000)
      } else {
        let extraSpace = 1.2
        let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace,
                                    longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
        region = MKCoordinateRegion(center: center, span: span)
      }
    }
    return mapView.regionThatFits(region)
  }
  
}


extension MapViewController: MKMapViewDelegate {
  
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is Location else { return nil }
    
    let identifier = "Location"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    
    if annotationView == nil {     // if no reusable cell available -->   create a new one
      let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      pinView.isEnabled = true
      pinView.canShowCallout = true                                   // pop-up with details
      pinView.animatesDrop = false
      pinView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
      
      let rightButton = UIButton(type: .detailDisclosure)
      rightButton.addTarget(self, action: #selector(showLocationDetails(_:)), for: .touchUpInside)
      pinView.rightCalloutAccessoryView = rightButton
      
      annotationView = pinView
    }
    
    if let annotationView = annotationView {
      annotationView.annotation = annotation
      let button = annotationView.rightCalloutAccessoryView as! UIButton
      if let index = locations.firstIndex(of: annotation as! Location) {
        button.tag = index                                                    // запазваме индекса на локацията в тага на бутона (за segue-то)
      }
    }
    
    return annotationView
  }
  
  @objc func showLocationDetails(_ sender: UIButton) {
    performSegue(withIdentifier: "EditLocation", sender: sender)
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      let index = (sender as! UIButton).tag
      selectedPin = CLLocationCoordinate2D(latitude: locations[index].latitude, longitude: locations[index].longitude)
      controller.locationToEdit = locations[index]
      controller.managedObjectContext = managedObjectContext
    }
  }
  
}
