//
//  DataController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/19/23.
//

import Foundation
import CoreData

//this file is to create the CoreData Stack:

class DataController {
   
    //Singleton Way:
    //static let shared = DataController(modelName: "VirtualTouristByMatson")
    
    let persistentContainer:NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { (_, error) in
            guard error == nil else {
                fatalError("Failed to load persistent stores: \(error!)")
            }
            completion?()
        }
    }

}
