
import UIKit

import UIKit

class HudView: UIView {
  var text = ""
  
  class func hud(inView view: UIView, animated: Bool) -> HudView {
    let hudView = HudView(frame: view.bounds)
    hudView.isOpaque = false
    hudView.show(animated: animated)
    view.addSubview(hudView)
    view.isUserInteractionEnabled = false
    
    return hudView
  }
  
  override func draw(_ rect: CGRect) {                              // called by UIKit !!!
    let boxWidth: CGFloat = 96
    let boxHeight: CGFloat = 96
    
    let boxRect = CGRect(
      x: round((bounds.size.width - boxWidth) / 2),
      y: round((bounds.size.height - boxHeight) / 2),
      width: boxWidth,
      height: boxHeight)
    
    let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
    UIColor(white: 0.6, alpha: 0.8).setFill()
    roundedRect.fill()
    
   
    guard let image = UIImage(named: "Checkmark") else { return }               // Draw checkmark
      let imagePoint = CGPoint(
        x: center.x - round(image.size.width / 2),
        y: center.y - round(image.size.height / 2) - boxHeight / 8)
      image.draw(at: imagePoint)
    
    
    let attribs = [                                                             // Draw the text
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
        NSAttributedString.Key.foregroundColor: UIColor.white
    ]

    let textSize = text.size(withAttributes: attribs)

    let textPoint = CGPoint(
      x: center.x - round(textSize.width / 2),
      y: center.y - round(textSize.height / 2) + boxHeight / 4)

    text.draw(at: textPoint, withAttributes: attribs)
  }
  
  // MARK: - Helper methods
  func show(animated: Bool) {
    if animated {
      alpha = 0
      transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
      UIView.animate(
        withDuration: 0.5,
        delay: 0,
        usingSpringWithDamping: 0.5,
        initialSpringVelocity: 0.3,
        options: [],
        animations: {
          self.alpha = 1
          self.transform = CGAffineTransform.identity             // back to original size
        }, completion: nil)

    }
  }
  
  func hide(animated: Bool) {
    if animated {
      UIView.animate(
        withDuration: 0.5,
        delay: 0,
        usingSpringWithDamping: 0.5,
        initialSpringVelocity: 0.3,
        options: [],
        animations: {
          self.alpha = 0
          self.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: nil)
    }
    superview?.isUserInteractionEnabled = true
    removeFromSuperview()
  }


}

