//
//  PhotoAlbumController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/13/23.
//

import Foundation
import UIKit
import MapKit
import CoreData
//allows the users to download and edit an album for a location

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoView: UICollectionView!
    
    //should be the selected pin
    var pin: Pin!
    
    //Core Data:
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Picture>!
    
    //need this
    var selectedLocation: CLLocation?
    
    //For the images:
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Picture> = Picture.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "pin", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
        
        setUpMap()
        
        // Set the delegate and data source of the collection view
        photoView.delegate = self
        photoView.dataSource = self
        
        setRows()
        
        //makeImages()
        
        // Reload the collection view to display the images
        photoView.reloadData()
        
    }
    
    @IBAction func newCollection(_ sender: UIButton) {
        
        //this should replace the images with a new set from Flickr.
        //use this number as the page parameter to get the random images.
        //when pressing this I should make a call to the random page url which will fetch
        //a different set of photos
        //make the call getPhotosRandom and populate the imageArray
        
        
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //return images.count
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
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
        let photo = fetchedResultsController.object(at: indexPath)
        
        if let imageData = photo.imageData {
            cell.photo.image = UIImage(data: imageData)
        } else {
            cell.photo.image = UIImage(named: "placeholder")
            
            // Start downloading the image asynchronously
            //converting the urls into data bytes...
            //how do I reference the urls again?
            //convert the imageURLS array to the downloads.
        }
        
        return cell
    }
    
    //to Delete the cell/photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedPhoto = fetchedResultsController.object(at: indexPath)
        
        // Delete the selected photo from Core Data
        dataController.viewContext.delete(selectedPhoto)
        
        // Save the changes to Core Data
        do {
            try dataController.viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
        
        // Update the fetched results controller to reflect the deletion
        try? fetchedResultsController.performFetch()
        
        // Animate the deletion in the collection view
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
        }, completion: nil)
        
        // Reload the collection view to reflect the updated data
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
    
    //    func makeImages(){
    //        // Convert the imageData to UIImage and populate the images array
    //        if let imageData = imageData {
    //            for data in imageData {
    //                if let image = UIImage(data: data) {
    //                    //images.append(image)
    //                    let imageModel = ImageModel(image: image, isDownloaded: false)
    //                    images.append(imageModel)
    //                }
    //            }
    //        }
    //
    //    }
    
    func setUpMap(){
    //annotate map to show location of photos downloaded from previous controller
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            mapView.addAnnotation(annotation)
            
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(region, animated: true)
        }
    }
}

//Now implement the is empty logic.
//then all you have to do is implement the new collection feature, then you should be done! Yay!  and refactor of course. 
//class PhotoAlbumViewController: UIViewController {
//    var pin: Pin!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if !pin.hasPhotos {
//            // Initiate the download of photos from Flickr
//            downloadPhotos()
//        } else {
//            // Load the saved photos from Core Data and display them
//            loadSavedPhotos()
//        }
//    }
//
//    func downloadPhotos() {
//        // Implement the logic to download photos from Flickr
//        // Once the download is complete, save the photos to Core Data
//        // Set the `hasPhotos` property of the pin to `true`
//        // Display the downloaded photos in the collection view
//    }
//
//    func loadSavedPhotos() {
//        // Implement the logic to fetch and display saved photos from Core Data
//    }
//}
//By implementing this logic in the PhotoAlbumViewController, you can ensure that the photos are immediately downloaded if there are no saved images for the selected pin.


