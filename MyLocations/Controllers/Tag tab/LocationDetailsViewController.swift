
import UIKit
import CoreLocation
import CoreData
import AVFoundation                                               // for checking camera access

private let dateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "dd.MM.YYYY  HH:mm"
  return formatter
}()

class LocationDetailsViewController: UITableViewController {
  
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var addPhotoLabel: UILabel!
  @IBOutlet weak var imageHeight: NSLayoutConstraint!
  
  var coordinates: CLLocationCoordinate2D!
  var placemark: String?
  var categoryName = "No Category"
  var date = Date()
  var managedObjectContext: NSManagedObjectContext!
  var descriptionText = ""
  var locationToEdit: Location? {
    didSet {
      if let location = locationToEdit {
        descriptionText = location.locationDescription
        categoryName = location.category
        coordinates = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        date = location.date
        placemark = location.placemark
      }
    }
  }
  var image: UIImage? {
    didSet {
      showImage(image)
    }
  }
  
  deinit {
    print("***************************** deinit \(self)")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let locationToEdit = locationToEdit {
      title = "Edit Location"
      if locationToEdit.hasPhoto, let photo = locationToEdit.photoImage {
        showImage(photo)                          // НЕ СЕ ЗАПИСВА в self.image --> ако не променим снимката, остава си стария файл ! ! !
      }                                           // само UIImagePickerController записва в self.image
    }
    
    descriptionTextView.text = descriptionText
    categoryLabel.text = categoryName
    latitudeLabel.text = String(format: "%.6f", coordinates.latitude)
    longitudeLabel.text = String(format: "%.6f", coordinates.longitude)
    if let placemark = placemark {
      addressLabel.text = placemark
    } else {
      addressLabel.text = "Не е намерен адрес"
    }
    dateLabel.text = dateFormatter.string(from: date)
    
    let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))     // Hide keyboard
    gestureRecognizer.cancelsTouchesInView = false
    tableView.addGestureRecognizer(gestureRecognizer)
    listenForBackgroundNotification()
  }
  
  @IBAction func done(_ sender: UIBarButtonItem) {
    guard let mainView = navigationController?.parent?.view else { return } // to cover NavBar and TabBar  --> NavController is in TabController (parent)
    let hudView = HudView.hud(inView: mainView, animated: true)
    
    let location: Location
    if let locationToEdit = locationToEdit {
      hudView.text = "Updated"
      location = locationToEdit
    } else {
      hudView.text = "Tagged"
      location = Location(context: managedObjectContext)          // CREATE to be saved in CoreData
      location.photoID = nil                                      // managedObjectContext създава Location с default-на стойност 0 (а не nil) ! ! !
    }
    location.placemark = placemark
    location.date = date
    location.latitude = coordinates.latitude
    location.longitude = coordinates.longitude
    location.locationDescription = descriptionTextView.text
    location.category = categoryName
    
    if let image = image {
      if !location.hasPhoto {
        location.photoID = Location.nextPhotoID() as NSNumber         //  ако няма снимка се създава ID, ако има - ползва се за пре-запис
      }
      if let data = image.jpegData(compressionQuality: 0.5) {         // data = image.jpegData(compressionQuality: 0.5)
        do {
          try data.write(to: location.photoURL, options: .atomic)
        } catch {
          print("Error writing file: \(error)")
        }
      }
    }

    
    do {
      try managedObjectContext.save()
      afterDelay(0.5) {
        hudView.hide(animated: true)
      }
      afterDelay(0.6) {
        self.navigationController?.popViewController(animated: true)
      }
    } catch  {
      fatalCoreDataError(error)
    }
  }
  
  @IBAction func cancel(_ sender: UIBarButtonItem) {
    navigationController?.popViewController(animated: true)
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "PickCategory" {
      let controller = segue.destination as! CategoryPickerViewController
      controller.selectedCategoryName = categoryName
    }
  }
  
  @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue) {    // Unwind Segue   in  CategoryPickerViewController
    let controller = segue.source as! CategoryPickerViewController
    categoryName = controller.selectedCategoryName
    categoryLabel.text = categoryName
  }
  
  
  // MARK: - Helper Methods
  @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
    let point = gestureRecognizer.location(in: tableView)
    let indexPath = tableView.indexPathForRow(at: point)
    if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 { return }
    descriptionTextView.resignFirstResponder()                    // Hide keyboard
  }
  
  func listenForBackgroundNotification() {
    NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification,
                                           object: nil, queue: OperationQueue.main) { [weak self] _ in
      if let weakSelf = self {
        if weakSelf.presentedViewController != nil {
          weakSelf.dismiss(animated: false, completion: nil)
        }
        weakSelf.descriptionTextView.resignFirstResponder()
      }
    }
  }

  func showImage(_ image: UIImage?) {
    imageView.image = image
    imageView.isHidden = false
    addPhotoLabel.text = ""
    imageHeight.constant = 260
    tableView.reloadData()
  }
  
  // MARK: - Table View Delegates
  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    if indexPath.section == 0 || indexPath.section == 1 {
      return indexPath
    } else {
      return nil
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if indexPath.section == 0 && indexPath.row == 0 {
      descriptionTextView.becomeFirstResponder()
    } else if indexPath.section == 1 && indexPath.row == 0 {
      tableView.deselectRow(at: indexPath, animated: true)
      DispatchQueue.main.async {                                   // DispatchQueue.main.async
        self.pickPhoto()
      }
    }
  }
}

// MARK: - Image Picker
extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  // MARK: - Helper Methods
  func pickPhoto() {
      let imagePicker = UIImagePickerController()
      imagePicker.delegate = self
      imagePicker.allowsEditing = true
      
      let alert = UIAlertController(title: "Избери снимка", message: nil, preferredStyle: .actionSheet)
      
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let action = UIAlertAction(title: "Камера", style: .default) { _ in
          imagePicker.sourceType = .camera
          if authStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
              DispatchQueue.main.async {                                                 // DispatchQueue.main.async
                if granted {
                  self.present(imagePicker, animated: true, completion: nil)
                } else {
                  imagePicker.dismiss(animated: true, completion: nil)
                  self.pickPhoto()
                }
              }
            }
          } else {
            self.present(imagePicker, animated: true, completion: nil)
          }
        }
        action.isEnabled = !(authStatus == .restricted || authStatus == .denied)
        alert.addAction(action)
      }
      alert.addAction(UIAlertAction(title: "Галерия", style: .default) { _ in
        imagePicker.sourceType = .photoLibrary
        self.present(imagePicker, animated: true, completion: nil) })
      alert.addAction(UIAlertAction.init(title: "Отказ", style: .cancel, handler: nil))
      
      self.present(alert, animated: true, completion: nil)
  }
  
  // MARK: - Image Picker Delegates
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage       //    info [ UIImagePickerController.InfoKey.editedImage ]
    dismiss(animated: true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
}
