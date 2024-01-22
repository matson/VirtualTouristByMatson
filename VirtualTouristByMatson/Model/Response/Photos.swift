//
//  Photos.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/14/23.
//

import Foundation

struct Photos: Codable {
    
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [Photo]
}
