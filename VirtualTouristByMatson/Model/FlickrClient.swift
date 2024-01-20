//
//  FlickrClient.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/14/23.
//

import Foundation
import UIKit

//For all API related code:

class FlickrClient {
    
    static let apiKey = "6af4caaf64a51bcb1aeb1ad1418f878e"
    
    enum Endpoints {
        
        static let baseFlickrAPI = "https://api.flickr.com/services/rest/?method="
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        
        
        case getPhotos(Float, Float)
        case getPhotosRandom(Int)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let lat, let long): return Endpoints.baseFlickrAPI + "flickr.photos.search\(FlickrClient.Endpoints.apiKeyParam)" + "&per_page=20&format=json&nojsoncallback=1&lat=\(lat)&lon=\(long)&radius=5"
            case .getPhotosRandom(let page):
                return Endpoints.baseFlickrAPI + "flickr.photos.getRecent\(FlickrClient.Endpoints.apiKeyParam)" + "&per_page=20&format=json&nojsoncallback=1&page=\(page)"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
        
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?, Bool) -> Void) -> URLSessionTask {
        
        // Create a data task with the URL
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response")
                return
            }
            guard let data = data else {
                completion(nil, error, false)
                return
            }
            let decoder = JSONDecoder()
            do {
                
                let jsonObject = try decoder.decode(ResponseType.self, from: data)
               
                completion(jsonObject, nil, true)
            } catch {
               
                completion(nil, error, false)
            }
        }

        // Start the data task
        task.resume()
        return task
    }
    
    class func getPhotos(lat: Float, long: Float, completion: @escaping (PhotoSearchResponse?, Error?, Bool) -> Void) {
        taskForGETRequest(url: Endpoints.getPhotos(lat, long).url, responseType: PhotoSearchResponse.self) { response, error, success in
            if let response = response {
                completion(response, nil, true)
            }else{
                completion(nil, error, false)
            }
        }
    }
    
    class func getPhotosRandom(lat: Float, long: Float, completion: @escaping (PhotoSearchResponse?, Error?, Bool) -> Void) {
        let randomPage = Int.random(in: 1...100) // Generate a random page number
        taskForGETRequest(url: Endpoints.getPhotosRandom(randomPage).url, responseType: PhotoSearchResponse.self) { response, error, success in
            if let response = response {
                
                completion(response, nil, true)
            } else {
               
                completion(nil, error, false)
            }
        }
    }
}

