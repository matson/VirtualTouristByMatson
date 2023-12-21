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
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the delegate and data source of the collection view
        photoView.delegate = self
        photoView.dataSource = self
        
        setRows()
        
        makeImages()
        
        // Reload the collection view to display the images
        photoView.reloadData()
        
    }
    
    @IBAction func newCollection(_ sender: UIButton) {
        
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let collectionViewWidth = collectionView.bounds.width
        let space: CGFloat = 3.0
        let numberOfItemsPerRow: CGFloat = 3
        let dimension = (collectionViewWidth - ((numberOfItemsPerRow - 1) * space)) / numberOfItemsPerRow

        return CGSize(width: dimension, height: dimension)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! VirtualTouristViewCell
        
        // Retrieve the imageData from the selected pin using the index path
        let imageData = images[indexPath.item]
        
        //set the image to the cell image
        cell.photo.image = imageData
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Get the selected item's index path
        let selectedIndexPath = indexPath
        
        // Perform the removal logic here
        // For example, you can remove the item from your data source array
//        dismiss(animated: true, completion: nil)
        
        // Reload the collection view to reflect the changes
        collectionView.reloadData()
    }
    
    func setRows(){
        // Create a new flow layout instance
        let layout = UICollectionViewFlowLayout()
        
        // Set the spacing between cells
        layout.minimumInteritemSpacing = 3.0
        layout.minimumLineSpacing = 3.0
        
        // Calculate the item size based on the available width
        let collectionViewWidth = photoView.bounds.width
        let numberOfItemsPerRow: CGFloat = 3
        let dimension = (collectionViewWidth - ((numberOfItemsPerRow - 1) * layout.minimumInteritemSpacing)) / numberOfItemsPerRow
        layout.itemSize = CGSize(width: dimension, height: dimension)
        
        // Set the collection view's layout
        photoView.collectionViewLayout = layout
    }
    
    func makeImages(){
        // Convert the imageData to UIImage and populate the images array
        if let imageData = imageData {
            for data in imageData {
                if let image = UIImage(data: data) {
                    images.append(image)
                }
            }
        }
    }
}


