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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoView: UICollectionView!
    var pin: Pin!
    var imageData: [Data]?
    var images: [UIImage] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate and data source of the collection view
        photoView.delegate = self
        photoView.dataSource = self
        
        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        // Convert the imageData to UIImage and populate the images array
        if let imageData = imageData {
                for data in imageData {
                    if let image = UIImage(data: data) {
                        images.append(image)
                    }
                }
            }
        
        // Reload the collection view to display the images
        photoView.reloadData()
        
    }
  
    @IBAction func newCollection(_ sender: UIButton) {
        
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! VirtualTouristViewCell
        
        // Retrieve the imageData from the selected pin using the index path
        let imageData = images[indexPath.item]
        
        //set the image to the cell image
        cell.photo.image = imageData
        
        return cell
    }
}


