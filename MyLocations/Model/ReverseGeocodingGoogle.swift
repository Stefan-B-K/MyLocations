
import CoreLocation


class ReverseGeocodingGoogle {
  
  private let keyAPI = "Google Geocoding API"
  var placemark: String?
  
  private struct GeocodingResults: Decodable {
    let results: [GeocodingResult]
  }

  private struct GeocodingResult: Decodable {
    let formatted_address: String
  }
  
//  func getAddress(for coordinates: CLLocation) async throws {
//    let domainURL = "https://maps.googleapis.com/maps/api/geocode/json?"
//    let API = getAPI(forKey: keyAPI)
//    let latLng = "latlng=\(coordinates.coordinate.latitude),\(coordinates.coordinate.longitude)"
//    let locationURL = URL(string: domainURL + latLng + "&key=" + API)!
//
//    let urlRequest = URLRequest(url: locationURL)
//    let (data, _) = try await URLSession.shared.data(for: urlRequest)
//    let results = try JSONDecoder().decode(GeocodingResults.self, from: data).results
//
//    if !results.isEmpty {
//      placemark = results[0].formatted_address
//    } else {
//      placemark = nil
//    }
//  }
  
  func getAddress(for coordinates: CLLocation) async {
    
    let fetchTask = Task { () -> [GeocodingResult] in
      let domainURL = "https://maps.googleapis.com/maps/api/geocode/json?"
      let API = getAPI(forKey: keyAPI)
      let latLng = "latlng=\(coordinates.coordinate.latitude),\(coordinates.coordinate.longitude)"
      let locationURL = URL(string: domainURL + latLng + "&key=" + API)!
      
      let urlRequest = URLRequest(url: locationURL)
      let (data, _) = try await URLSession.shared.data(for: urlRequest)
      return try JSONDecoder().decode(GeocodingResults.self, from: data).results
    }
    
    do {
      let results = try await fetchTask.value
      if !results.isEmpty {
        placemark = results[0].formatted_address
      } else {
        placemark = nil
      }
    } catch {
      fatalError("************** Error from Google geocoder ****************")
    }
  }
  
  
  
  
}

