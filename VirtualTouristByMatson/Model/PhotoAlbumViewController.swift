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
        
        //logic for if it has downloaded photos OR not
        
        //IF DOES NOT
        if pin.photo?.count == 0 {
            print("no photos")
            // Initiate the download of photos from Flickr
            FlickrImage.shared.downloadImages(forPin: pin, dataController: dataController) { images, error in
                if let error = error {
                    print("there is an error with the downloads")
                } else if let images = images {
                    print("got here to images")
                    //assign to array
                    self.downloadedImages = images
                    print("got the array here")
                    DispatchQueue.main.async {
                        self.photoView.reloadData()
                    }
                }
            }
            //IF DOES
        } else {
            print("has photos")
        }
        
        setUpMap()
        
        // Set the delegate and data source of the collection view
        photoView.delegate = self
        photoView.dataSource = self
        
        setRows()
        
        print(downloadedImages)
        
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
        if fetchedResultsController.sections?[section].numberOfObjects ?? 0 > 0 {
            // Return the number of objects from the fetched results controller
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        } else {
            // Return the count of downloaded images if no photos are present
            return downloadedImages.count
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
        print("got to the beginning")
        print(downloadedImages)
        if fetchedResultsController.sections?[indexPath.section].numberOfObjects ?? 0 > 0 {
            print("getting stuff from fetch")
            // Retrieve the imageData from the fetched results controller using the index path
            let photo = fetchedResultsController.object(at: indexPath)
            
            if let imageData = photo.imageData {
                cell.photo.image = UIImage(data: imageData)
            } else {
                cell.photo.image = UIImage(named: "placeholder")
            }
        } else {
            print("getting from image array")
            print(downloadedImages)
            // Retrieve the image from the downloaded images array using the index path
            let image = downloadedImages[indexPath.item]
            cell.photo.image = image
        }
        print("got to the end")
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



