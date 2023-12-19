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
    
    // MARK: Table View Data Source
    
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return self.allVillains.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VillainCollectionViewCell", for: indexPath) as! VillainCollectionViewCell
//        let villain = self.allVillains[(indexPath as NSIndexPath).row]
//
//        // Set the name and image
//        cell.label.text = villain.name
//        cell.villainImageView?.image = UIImage(named: villain.imageName)
//        //cell.schemeLabel.text = "Scheme: \(villain.evilScheme)"
//
//        return cell
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {
//
//        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "VillainDetailViewController") as! VillainDetailViewController
//        detailController.villain = self.allVillains[(indexPath as NSIndexPath).row]
//        self.navigationController!.pushViewController(detailController, animated: true)
//
//    }
    
}
