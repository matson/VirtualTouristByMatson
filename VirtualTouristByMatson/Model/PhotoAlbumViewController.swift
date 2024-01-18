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
    var downloadedImages = [UIImage]()
    var urlsArray = [String]()
    
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
        let lat = pin.latitude
        let long = pin.longitude
        
        FlickrClient.getPhotos(lat: lat, long: long) { response, error, success in
            if success {
                let photos = response!.photos.photo
                var newUrlsArray = [String]()
                
                for photo in photos {
                    let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                    newUrlsArray.append(photoURLString)
                    
                    // Download the image data
                    FlickrImage.shared.downloadData(from: photoURLString) { imageData, error in
                        if let error = error {
                            print("There is an error with the image download: \(error)")
                        } else if let imageData = imageData {
                            DispatchQueue.main.async {
                                // Create a new Picture instance
                                let picture = Picture(context: self.dataController.viewContext)
                                picture.pin = self.pin
                                
                                // Set the imageData attribute
                                picture.imageData = imageData
                                
                                // Save the Picture instance and the data to Core Data
                                do {
                                    try self.dataController.viewContext.save()
                                } catch {
                                    // Handle error
                                    print("Failed to save Picture to Core Data: \(error)")
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.urlsArray = newUrlsArray
                    self.photoView.reloadData()
                }
            } else {
                // Handle error
            }
        }
        
        setUpMap()
        
        // Set the delegate and data source of the collection view
        photoView.delegate = self
        photoView.dataSource = self
        
        setRows()
        
        // Reload the collection view to display the images
        photoView.reloadData()
        
    }
    
    @IBAction func newCollection(_ sender: UIButton) {
        
        let lat = pin.latitude
        let long = pin.longitude
        //this should replace the images with a new set from Flickr.
        
        FlickrClient.getPhotosRandom(lat: lat, long: long) { response, error, success in
            if success {
                let photos = response!.photos.photo
                var newUrlsArray = [String]()
                
                for photo in photos {
                    let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                    newUrlsArray.append(photoURLString)
                    
                    // Download the image data
                    FlickrImage.shared.downloadData(from: photoURLString) { imageData, error in
                        if let error = error {
                            print("There is an error with the image download: \(error)")
                        } else if let imageData = imageData {
                            DispatchQueue.main.async {
                                // Create a new Picture instance
                                let picture = Picture(context: self.dataController.viewContext)
                                picture.pin = self.pin
                                
                                // Set the imageData attribute
                                picture.imageData = imageData
                                
                                // Save the Picture instance to Core Data
                                do {
                                    try self.dataController.viewContext.save()
                                } catch {
                                    // Handle error
                                    print("Failed to save Picture to Core Data: \(error)")
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.urlsArray = newUrlsArray
                    self.photoView.reloadData()
                }
            } else {
                // Handle error
            }
        }
        
        //when pressing this I should make a call to the random page url which will fetch
        //a different set of photos
        //make the call getPhotosRandom and populate the urlArray with the new urls
        //find a way to populate the cells with this new random data
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if fetchedResultsController.sections?[section].numberOfObjects ?? 0 > 0 {
            // Return the number of objects from the fetched results controller
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        } else {
            return urlsArray.count
        }
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
        
        if fetchedResultsController.sections?[indexPath.section].numberOfObjects ?? 0 > 0 {
            print("should not be in here either.")
            
            configureCell(cell, at: indexPath)
            
        } else {
            print("should not be in here")
            //download each image individually by indexing array:
            // Check if the index is within the bounds of the urlsArray
            if indexPath.item < urlsArray.count {
                let url = urlsArray[indexPath.item]
                
                FlickrImage.shared.downloadImage(from: url) { image, error in
                    if let error = error {
                        print("There is an error with the image download: \(error)")
                    } else if let image = image {
                        DispatchQueue.main.async {
                            // Check if the cell is still visible at the same index path
                            if let currentIndexPath = collectionView.indexPath(for: cell), currentIndexPath == indexPath {
                                cell.photo.image = image
                            }
                        }
                    }
                }
            }
        }
        return cell
        
    }
    
    //to Delete the cell/photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if fetchedResultsController.sections?[indexPath.section].numberOfObjects ?? 0 > 0 {
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
        } else {
            // Handle deletion for the urlsArray
            urlsArray.remove(at: indexPath.item)
            
            // Animate the deletion in the collection view
            collectionView.performBatchUpdates({
                collectionView.deleteItems(at: [indexPath])
            }, completion: nil)
        }
        
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
    
    func configureCell(_ cell: VirtualTouristViewCell, at indexPath: IndexPath) {
        // Retrieve the imageData from the fetched results controller using the index path
        let picture = fetchedResultsController.object(at: indexPath)
        if let imageData = picture.imageData {
            print("should not be here")
            cell.photo.image = UIImage(data: imageData)
        } else {
            print("only here")
            cell.photo.image = UIImage(named: "placeholder")
            //for some reason there hasn't been data saved for the picture for this pin
            //steps:
            let lat = pin.latitude
            let long = pin.longitude
            
            FlickrClient.getPhotos(lat: lat, long: long) { response, error, success in
                if success {
                    let photos = response!.photos.photo
                    
                    for photo in photos {
                        let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                        
                        // Download the image data
                        FlickrImage.shared.downloadData(from: photoURLString) { imageData, error in
                            if let error = error {
                                print("There is an error with the image download: \(error)")
                            } else if let imageData = imageData {
                                DispatchQueue.main.async {
                                    // Check if the cell is still visible at the same index path
                                   
                                        // Update the cell's image with the downloaded image
                                    cell.photo.image = UIImage(data: imageData)
                                    //}
                                    
                                    // Set the imageData attribute
                                    picture.imageData = imageData
                                    
                                    // Save the Picture instance and the data to Core Data
                                    do {
                                        try self.dataController.viewContext.save()
                                    } catch {
                                        // Handle error
                                        print("Failed to save Picture to Core Data: \(error)")
                                    }
                                }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.photoView.reloadData()
                    }
                } else {
                    // Handle error
                }
            }
        }
    }
}



