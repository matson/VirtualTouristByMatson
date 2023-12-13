//
//  PhotoAlbumController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/13/23.
//

import Foundation
import UIKit
import MapKit
//allows the users to download and edit an album for a location

class PhotoAlbumViewController: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoView: UICollectionView!
    //if the user does not have a photo album associated with pin, then app downloads Flickr images associated with the lat/long of pin.
    
    //if there are images, display in a collection view.
    
    //pictures and albums are only from Flickr.
    //collection view should be present and newcollection button at the bottom?
    //mapView up top?
    @IBAction func newCollection(_ sender: UIButton) {
    }
    
    
}
