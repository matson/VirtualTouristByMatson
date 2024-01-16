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
    
    func downloadImages(forPin pin: Pin, dataController: DataController, completion: @escaping ([UIImage]?, Error?) -> Void) {
        
        let lat = pin.latitude
        let long = pin.longitude
        
        FlickrClient.getPhotos(lat: lat, long: long) { response, error, success in
            if success {
                
                var downloadedImages = [UIImage]()
                // Access the photo array
                let photos = response!.photos.photo
                
                // Create a dispatch group to wait for all image downloads to complete
                let downloadGroup = DispatchGroup()
                
                // Iterate over each photo object
                for photo in photos {
                    
                    let picture = Picture(context: dataController.viewContext)
                    
                    // Construct the photo URL using the properties of the photo object
                    let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                    
                    //associate the image with the pin
                    picture.pin = pin
                    
                    // Enter the dispatch group before starting the download
                    downloadGroup.enter()
                    
                    // Download the image data from the URL
                    let session = URLSession.shared
                    let url = URL(string: photoURLString)!
                    
                    let task = session.dataTask(with: url) { (data, response, error) in
                        defer {
                            
                            // Leave the dispatch group when the download is complete
                            downloadGroup.leave()
                        }
                        
                        if let error = error {
                            print("Error downloading image: \(error.localizedDescription)")
                            return
                        }
                        
                        guard let data = data, let image = UIImage(data: data) else {
                            print("Invalid image data")
                            return
                        }
                        
                        // Convert the image to binary data
                        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                            print("Error converting image to data")
                            return
                        }
                        
                        // Set the image data for the Picture entity
                        picture.imageData = imageData
                        downloadedImages.append(image)
                    }
                    
                    task.resume()
                }
                // Wait for all image downloads to complete
                //this will produce an image array. 
                downloadGroup.notify(queue: .main) {
                    try? dataController.viewContext.save()
                    completion(downloadedImages, nil)
                    
                }
                
            }else{
                completion(nil, error)
            }
        }
    }
}
