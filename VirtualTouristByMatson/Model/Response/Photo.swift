//
//  Photo.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/14/23.
//

import Foundation

//the actual photo object.  These will be used to create the urls

struct Photo: Codable {
    
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
