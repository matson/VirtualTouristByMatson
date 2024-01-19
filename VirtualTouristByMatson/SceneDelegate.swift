//
//  SceneDelegate.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/12/23.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTouristByMatson")
    

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
       // DataController.shared.load()
        dataController.load()
        
        
        if let navigationController = window?.rootViewController as?
            UINavigationController {
            if let travelLocationsViewController = navigationController.topViewController as? TravelLocationsViewController {
                travelLocationsViewController.dataController = dataController
            }
        }
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }


}

