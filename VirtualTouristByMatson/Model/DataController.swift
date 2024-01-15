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
    
    //hold the persistent container
    //hold the persistent store, and help with the context

    let persistentContainer:NSPersistentContainer

    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }

    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError("Failed to load persistent stores: \(error!)")
            }
            //self.autoSaveViewContext()
            completion?()
        }
    }

}
