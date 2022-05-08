
import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  lazy var managedObjectContext = persistentContainer.viewContext
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let _ = (scene as? UIWindowScene) else { return }
    let tabController = window!.rootViewController as! UITabBarController
    
    if let tabViewControllers = tabController.viewControllers {
      var navController = tabViewControllers[0] as! UINavigationController
      let controller1 = navController.viewControllers.first as! CurrentLocationViewController
      controller1.managedObjectContext = managedObjectContext
      
      navController = tabViewControllers[1] as! UINavigationController
      let controller2 = navController.viewControllers.first as! LocationsViewController
      controller2.managedObjectContext = managedObjectContext
      
      navController = tabViewControllers[2] as! UINavigationController
      let controller3 = navController.viewControllers.first as! MapViewController
      controller3.managedObjectContext = managedObjectContext
    }
    listenForFatalCoreDataNotifications(tabController)
  }
  
  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }
  
  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }
  
  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }
  
  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
    
    // Save changes in the application's managed object context when the application transitions to the background.
    saveContext()
  }
  
  // MARK: - Core Data stack
  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "MyLocations")
    container.loadPersistentStores(completionHandler: { _, error in
      if let error = error as NSError? {
        fatalError("Could not load data store: \(error)")
      }
    })
    return container
  }()
  
  // MARK: - Core Data Saving support
  func saveContext () {
    if managedObjectContext.hasChanges {
      do {
        try managedObjectContext.save()
      } catch {
        let nserror = error as NSError
        fatalCoreDataError(nserror)
      }
    }
  }

}

