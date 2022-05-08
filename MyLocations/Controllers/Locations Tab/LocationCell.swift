
import UIKit

class LocationCell: UITableViewCell {

  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var photoImageView: UIImageView!
  
  
  override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  
  // MARK: - Helper Method
  func configure(for location: Location) {
    if location.locationDescription.isEmpty {
      descriptionLabel.text = "(No Description)"
    } else {
      descriptionLabel.text = location.locationDescription
    }

    if let placemark = location.placemark {
      addressLabel.text = placemark
    } else {
      addressLabel.text = String(
        format: "Lat: %.6f, Long: %.6f",
        location.latitude,
        location.longitude)
    }
    photoImageView.image = thumbnail(for: location)
    photoImageView.tintColor = .label
    photoImageView.layer.cornerRadius = photoImageView.bounds.size.width / 2
    photoImageView.clipsToBounds = true
    separatorInset = UIEdgeInsets(top: 0, left: 82, bottom: 0, right: 0)
  }

  func thumbnail(for location: Location) -> UIImage {
    if location.hasPhoto, let image = location.photoImage {
      return image.resized(width: 52, height: 52, contentMode: .aspectFill)
    }
    return UIImage(named: "No Photo")!
  }

}
