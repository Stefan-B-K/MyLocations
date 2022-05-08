
import UIKit

extension UIImage {
  
  enum ContentMode {
    case aspectFill, aspectFit
  }
  
  func resized(width: Int, height: Int, contentMode: ContentMode) -> UIImage {
    let bounds = CGSize(width: width, height: height)
    let ratio = (contentMode == .aspectFill) ? max(bounds.width / size.width, bounds.height / size.height)
    : min(bounds.width / size.width, bounds.height / size.height)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(bounds, true, 0)
    var rect = CGRect(origin: CGPoint.zero, size: newSize)
    if (contentMode == .aspectFill && newSize.width > bounds.width) ||
        (contentMode == .aspectFit && newSize.width < bounds.width) {
      let offset = (bounds.width - newSize.width) / 2
      rect.origin.x = offset
    } else {
      let offset = (bounds.height - newSize.height) / 2
      rect.origin.y = offset
    }
    draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
}
