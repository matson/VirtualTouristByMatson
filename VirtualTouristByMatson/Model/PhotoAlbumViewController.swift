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

//fix fetchResultsController

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoView: UICollectionView!
    
    //should be the selected pin
    var pin: Pin!
    
    //Core Data:
    var dataController:DataController!
    var fetchedResultsController: NSFetchedResultsController<Picture>!
   
    //need this
    var selectedLocation: CLLocation?
    var downloadedImages = [UIImage]()
    
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
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
        //cases:
        //pin can have pictures:
        let lat = pin.latitude
        let long = pin.longitude
        
        //In the case that the pin has no data or pictures,
        //the download here begins.
        if fetchedResultsController.fetchedObjects?.count == 0 {
           
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
                                    print("saved the picture and data")
                                    // Create a new Picture instance
                                    let picture = Picture(context: self.dataController.viewContext)
                                    //assign the new picture to the selected pin.
                                    picture.pin = self.pin
                                    
                                    // Set the imageData attribute
                                    picture.imageData = imageData
                                    
                                    // Save the changes to Core Data
                                    do {
                                        try self.dataController.viewContext.save()
                                        self.photoView.reloadData()
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
                    //there are no picture objects associated with Pin.
                    //may need to download here
                }
                
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
        
        //first remove all photos from Core Data associated with the Pin.
        guard let presentPhotos = fetchedResultsController.fetchedObjects else{
            return
        }
        
        for index in presentPhotos {
            self.dataController.viewContext.delete(index)
            try? self.dataController.viewContext.save()
        }
        
        let lat = pin.latitude
        let long = pin.longitude
        //this should replace the images with a new set from Flickr.
        FlickrClient.getPhotosRandom(lat: lat, long: long) { response, error, success in
            
            if success {
                let photos = response!.photos.photo
                
                for photo in photos {
                    let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
        
                    FlickrImage.shared.downloadData(from: photoURLString) { imageData, error in
                        if let error = error {
                            print("There is an error with the image download: \(error)")
                        } else if let imageData = imageData {
                            DispatchQueue.main.async {
                               
                                // Create a new  random Picture instance
                                let picture = Picture(context: self.dataController.viewContext)
                                //assign the new picture to the selected pin.
                                picture.pin = self.pin
                                
                                // Set the random imageData attribute
                                picture.imageData = imageData
                                
                                // Save the changes to Core Data
                                do {
                                    try self.dataController.viewContext.save()
                                    self.photoView.reloadData()
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
                print("error")
            }
            print("Inside FlickrClient.getPhotosRandom completion block")
        }
    }
    
    // MARK: Collection View Data Source
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        
        //assuming that by this stage all pins have pictures
        //if the pin has imageData assoicated with those pictures
        let picture = fetchedResultsController.object(at: indexPath)
        if let imageData = picture.imageData {
           
            cell.photo.image = UIImage(data: imageData)
        }else{
            //if the Picture has no imageData itself start a download
            //show a placeholder image:
            cell.photo.image = UIImage(named: "placeholder")
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
                                    // Set the imageData to the Picture attribute:
                                    picture.imageData = imageData
                                    
                                    //then populate the cell:
                                    cell.photo.image = UIImage(data: imageData)
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
        return cell
    }
    
    //to Delete the cell/photo
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let selectedPhoto = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(selectedPhoto)
        try? dataController.viewContext.save()
        
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
    
//    func configureCell(_ cell: VirtualTouristViewCell, at indexPath: IndexPath) {
//        //put logic here
//    }
}
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    //to update the cells
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if (newIndexPath != nil) {
                DispatchQueue.main.async {
                    self.photoView.insertItems(at: [newIndexPath!])
                }
            }
        case .delete:
            if ((indexPath != nil)) {
                self.photoView.deleteItems(at: [indexPath!])
            }
        case .update:
            if ((indexPath != nil)) {
                self.photoView.reloadItems(at: [newIndexPath!])
            }
        default:
            break
        }
    }
}





