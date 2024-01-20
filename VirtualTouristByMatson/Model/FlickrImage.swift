//
//  FlickrImage.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 1/16/24.
//

import Foundation
import UIKit

class FlickrImage {
    
    //this class serves as holding the functionality of downloading images using the API
    
    static let shared = FlickrImage()
    
    //retrieve just the raw data
    func downloadData(from url: String, completion: @escaping (Data?, Error?) -> Void) {
        
        guard let imageUrl = URL(string: url) else {
            completion(nil, nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: imageUrl) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, nil)
                return
            }
            
            completion(data, nil)
        }
        
        task.resume()
    }
    
}
