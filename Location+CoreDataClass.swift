
import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject {
  
  var hasPhoto: Bool {
    return photoID != nil
  }
  
  var photoURL: URL {
    assert(photoID != nil, "No photo ID set")
    let filename = "Photo-\(photoID!.intValue).jpg"
    return appDocsDirectory.appendingPathComponent(filename)
  }

  var photoImage: UIImage? {
    return UIImage(contentsOfFile: photoURL.path)
  }

  class func nextPhotoID() -> Int {
    let userDefaults = UserDefaults.standard
    let currentID = userDefaults.integer(forKey: "PhotoID")
    userDefaults.set(currentID + 1, forKey: "PhotoID")
    return currentID
  }
  
  func removePhotoFile() {
    if hasPhoto {
      do {
        try FileManager.default.removeItem(at: photoURL)
      } catch {
        print("Error removing file: \(error)")
      }
    }
  }


}



extension Location: MKAnnotation {
  
  public var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
  
  public var title: String? {
    if locationDescription.isEmpty {
      return "(No Description)"
    } else {
      return locationDescription
    }
  }
  
  public var subtitle: String? { category }
}
