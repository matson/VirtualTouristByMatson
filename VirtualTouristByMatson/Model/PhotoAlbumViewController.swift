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

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoView: UICollectionView!
    //to fetch from CoreData
    var pin: Pin!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    //if the user does not have a photo album associated with pin, then app downloads Flickr images associated with the lat/long of pin.
    
    //if there are images, display in a collection view.
    
    //pictures and albums are only from Flickr.
    //collection view should be present and newcollection button at the bottom?
    //mapView up top?
    
    @IBAction func newCollection(_ sender: UIButton) {
        
    }
    
    
    // MARK: Collection View Data Source
    
    // Implement the UICollectionViewDataSource methods
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return pin.imageData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! VirtualTouristViewCell
        
        // Retrieve the imageData from the selected pin using the index path
        let imageData = pin.imageData[indexPath.item]
        
        // Set the image of the cell using the retrieved imageData
        cell.photo.image = UIImage(data: imageData)
        
        return cell
    }
}


