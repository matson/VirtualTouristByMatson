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
    
    //https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=6af4caaf64a51bcb1aeb1ad1418f878e&format=json&nojsoncallback=1&lat=37.7749&lon=-122.4194&radius=5
    
    static let apiKey = "6af4caaf64a51bcb1aeb1ad1418f878e"
    //secret: 62e462df315c7ab4
    
    enum Endpoints {
        
        static let baseFlickrAPI = "https://api.flickr.com/services/rest/?method="
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        
        
        case getPhotos(Float, Float)
        case getPhotosRandom(Int)
        
        var stringValue: String {
            switch self {
            case .getPhotos(let lat, let long): return Endpoints.baseFlickrAPI + "flickr.photos.search\(FlickrClient.Endpoints.apiKeyParam)" + "&format=json&nojsoncallback=1&lat=\(lat)&lon=\(long)&radius=5"
            case .getPhotosRandom(let page):
                        let randomPage = Int.random(in: 1...100) // Generate a random page number
                return Endpoints.baseFlickrAPI + "flickr.photos.search\(FlickrClient.Endpoints.apiKeyParam)" + "&format=json&nojsoncallback=1&page=\(randomPage)"
              
                
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
    
    class func getPhotosRandom(){
        //use the random url instead of the normal one.
    }
}

