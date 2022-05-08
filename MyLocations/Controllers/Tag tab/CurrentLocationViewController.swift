
import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  @IBOutlet weak var latitudeTextLabel: UILabel!
  @IBOutlet weak var longitudeTextLabel: UILabel!
  @IBOutlet weak var containerView: UIView!
  
  
  let geolocation = Geolocation.shared
  let geocoderGoogle = ReverseGeocodingGoogle()
  var managedObjectContext: NSManagedObjectContext!
  
  var logoVisible = false
  var stoppedLocation: Bool?
  let logoButtonCenterY: CGFloat = 220
  lazy var logoButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
    button.sizeToFit()
    button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
    button.center.x = self.view.bounds.midX
    button.center.y = logoButtonCenterY
    return button
  }()
  var soundID: SystemSoundID = 0                                  // 0 =  NO sound
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    geolocation.caller = self
    messageLabel.text = ""
    updateLabels()
    loadSoundEffect("Sound.caf")
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = false
  }
  
  @IBAction func getLocation(_ sender: UIButton) {
    if geolocation.updating {
      geolocation.stopLocationManager()
      stoppedLocation = true
    } else {
      listenForLocationServiceDeniedNotification(self)
      geolocation.getLocation()
      if logoVisible {
        hideLogoView()
      }
      stoppedLocation = false
    }
    updateLabels()
  }
  
  // MARK: - CLLocationManager Delegate
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    guard (error as NSError).code != CLError.locationUnknown.rawValue else { return }     // if .locationUnknown  --> skip the error
    geolocation.lastError = error
    geolocation.stopLocationManager()
    updateLabels()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    geolocation.updateLocations(locations)
    updateLabels()
    if let location = geolocation.location {
      Task {                                                      //  ============= REVERSE GEOCODING ================
        await geocoderGoogle.getAddress(for: location)
        if let placemark = geocoderGoogle.placemark {
          if addressLabel.text != placemark {
            addressLabel.text = geocoderGoogle.placemark
            playSoundEffect()
          }
        } else {
          addressLabel.text = "Не е открит адрес"
        }
      }
    }
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      controller.coordinates = geolocation.location?.coordinate
      controller.placemark = geocoderGoogle.placemark
      controller.managedObjectContext = managedObjectContext
      if geolocation.updating {
        geolocation.stopLocationManager()
        stoppedLocation = true
        updateLabels()
      }
    }
  }
  
  // MARK: - Helper Methods
  func updateLabels() {
    
    if let location = geolocation.location {
      latitudeLabel.text = String(format: "%.6f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.6f", location.coordinate.longitude)
      tagButton.isHidden = false
      latitudeTextLabel.isHidden = false
      longitudeTextLabel.isHidden = false
      messageLabel.text = "За отбелязване натиснете бутон\n" + "'Тагване'"
      addressLabel.text = geocoderGoogle.placemark != nil ? geocoderGoogle.placemark! : ""
    } else {
      latitudeTextLabel.isHidden = true
      longitudeTextLabel.isHidden = true
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      tagButton.isHidden = true
      if let error = geolocation.lastError as NSError? {
        if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
          messageLabel.text = "Забранена услуга за локация!"
        } else {
          messageLabel.text = "Грешка при определяне на локацията"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        messageLabel.text = "Изключена услуга за локация!"
      } else if geolocation.updating {
        messageLabel.text = "Търсене..."
      } else {
        showLogoView()                                            //  showLogoView()
      }
      addressLabel.text = ""
    }
    configGetButton()
  }
  
  func configGetButton() {
    let spinnerTag = 1000
    if geolocation.updating {
      getButton.setTitle("СПРИ", for: .normal)
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center.x = view.bounds.midX
        spinner.center.y = view.bounds.midY + 100
        spinner.startAnimating()
        spinner.tag = spinnerTag
        view.addSubview(spinner)
      }
    } else {
      getButton.setTitle("Местоположение", for: .normal)
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }
  
  func showLogoView() {
    if logoVisible { return }
    logoVisible = true
    view.addSubview(logoButton)
    
    guard stoppedLocation != nil else {                           // if loading on start, no roll-in animation
      containerView.isHidden = true
      return }
    let centerX = view.bounds.midX
    logoButton.center.x = -view.bounds.size.width * 2           // starting point for Animation
    logoButton.center.y = logoButtonCenterY

    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = CAMediaTimingFillMode.forwards
    panelMover.duration = 0.5
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint: CGPoint(x: 4 * centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    panelMover.delegate = self                                    //  delegate shold be the animation with longest duration
    containerView.layer.add(panelMover, forKey: "panelMoverIn")

    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = CAMediaTimingFillMode.forwards
    logoMover.duration = 0.3
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    logoButton.layer.add(logoMover, forKey: "logoMover")

    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = CAMediaTimingFillMode.forwards
    logoRotator.duration = 0.3
    logoRotator.fromValue = 0.0
    logoRotator.toValue = 2 * Double.pi
    logoRotator.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotatorIn")
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2           // starting point for Animation
    containerView.center.y = 40 + containerView.bounds.midY
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = CAMediaTimingFillMode.forwards
    panelMover.duration = 0.5
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = CAMediaTimingFillMode.forwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    logoMover.delegate = self                                     //  delegate shold be the animation with longest duration
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = CAMediaTimingFillMode.forwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * Double.pi
    logoRotator.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
  }
  
  // MARK: - Animation Delegate Methods
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    if !logoVisible {
      containerView.layer.removeAllAnimations()
      containerView.center.x = view.bounds.midX
      containerView.center.y = 40 + containerView.bounds.midY
      logoButton.layer.removeAllAnimations()
      logoButton.removeFromSuperview()
    } else {
      containerView.layer.removeAllAnimations()
      containerView.isHidden = true
      logoButton.layer.removeAllAnimations()
      logoButton.center.x = view.bounds.midX
      logoButton.center.y = logoButtonCenterY
    }
  }
  
  // MARK: - Sound effects
  func loadSoundEffect(_ name: String) {
    if let path = Bundle.main.path(forResource: name, ofType: nil) {
      let fileURL = URL(fileURLWithPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound: \(path)")
      }
    } else {
      print("Audio file for the soind missing")
    }
  }

  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }

  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
  }

  
}

