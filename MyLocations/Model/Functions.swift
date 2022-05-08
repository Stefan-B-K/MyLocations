
import UIKit

let appDocsDirectory: URL = {
  return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}()


func afterDelay(_ seconds: Double, run: @escaping () -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: run)
}


func getAPI(forKey: String) -> String {
  let dataFilePath = Bundle.main.url(forResource: "Private", withExtension: "plist")
  let data = try! Data(contentsOf: dataFilePath!)
  let result = try! PropertyListDecoder().decode([String:String].self, from: data)
  return result[forKey]!
}


let dataSaveFailedNotification = Notification.Name(rawValue: "DataSaveFailedNotification")
func fatalCoreDataError(_ error: Error) {
  NotificationCenter.default.post(name: dataSaveFailedNotification, object: nil)
}


let locationServiceDeniedNotification = Notification.Name(rawValue: "LocationServiceDeniedNotification")
func locationServiceDenied() {
  NotificationCenter.default.post(name: locationServiceDeniedNotification, object: nil)
}


func listenForFatalCoreDataNotifications(_ controller: UIViewController) {
  NotificationCenter.default.addObserver(forName: dataSaveFailedNotification,
                                         object: nil, queue: OperationQueue.main) { [weak controller] _ in
    let alert = UIAlertController(
      title: "Internal Error",
      message: """
      There was a fatal error in the app and it cannot continue.
      
      Press OK to terminate the app. Sorry for the inconvenience.
      """,
      preferredStyle: .alert)
    
    let action = UIAlertAction(title: "Ясно", style: .default) { _ in
      let exception = NSException(                                    // provides more information to the crash log than  fatalError()
        name: NSExceptionName.internalInconsistencyException,
        reason: "Fatal Core Data error",
        userInfo: nil)
      exception.raise()
    }
    alert.addAction(action)
    if let weakController = controller {
      weakController.present(alert, animated: true, completion: nil)
    }
  }
}


func listenForLocationServiceDeniedNotification(_ controller: UIViewController) {
  NotificationCenter.default.addObserver(forName: locationServiceDeniedNotification,
                                         object: nil, queue: OperationQueue.main) { [weak controller] _ in
    let alert = UIAlertController(
      title: "Забранена услуга за локация!",
      message: "Разрешете усугата за локация в Настройки!\n" + "Без улугата приложението е безполезно.",
      preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "Ясно", style: .default, handler: nil)
    alert.addAction(okAction)
    if let weakController = controller {
      weakController.present(alert, animated: true, completion: nil)
    }
  }
}



