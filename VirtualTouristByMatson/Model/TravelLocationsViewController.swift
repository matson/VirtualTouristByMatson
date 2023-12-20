//
//  ViewController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/12/23.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    var dataController:DataController!
    var latitude: Float = 0.00
    var longitude: Float = 0.00
    var photoURLs: [String] = []
    var downloadedImages: [UIImage] = []
    
    
    //state should save
    //Tapping and holding map should add a pin.
    //When pin is tapped, it will navigate to the photo album view associated with pin
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        // Get the dataController instance from the AppDelegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        setUpMap()
        
        // Add a long press gesture recognizer to the MapView
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        //show all pins that have been saved.
        getPins()
        
        
    }
    // MARK: Helper Functions
    
    func getPins(){
        // Fetch the saved pins from Core Data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Pin")
        
        do {
            let pins = try managedContext.fetch(fetchRequest)
            
            // Add the fetched pins as annotations on the map
            for pin in pins {
                let latitude = pin.value(forKey: "latitude") as? Float ?? 0.0
                let longitude = pin.value(forKey: "longitude") as? Float ?? 0.0
                
                let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                mapView.addAnnotation(annotation)
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func setUpMap(){
        // Define the initial region of the map
        let initialLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let regionRadius: CLLocationDistance = 3000
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        
        // Set the initial region of the map
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //to ADD a pin
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let lat = Float(coordinate.latitude)
            let long = Float(coordinate.longitude)
            
            // Create a new instance of the Pin entity
            let pin = Pin(context: dataController.viewContext)
            pin.latitude = lat
            pin.longitude = long
            
            try? self.dataController.viewContext.save()
            
            FlickrClient.getPhotos(lat: lat, long: long) { response, error, success in
                if success {
                    // Access the photo array
                    let photos = response!.photos.photo
                    
                    // Create a dispatch group to wait for all image downloads to complete
                    let downloadGroup = DispatchGroup()
                    
                    // Iterate over each photo object
                    for photo in photos {
                        let pic = Picture(context: self.dataController.viewContext)
                        
                        // Construct the photo URL using the properties of the photo object
                        let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                        
                        // Set the photo URL and associate it with the pin
                        //pic.imageURL = photoURLString
                        pic.pin = pin
                        
                        // Enter the dispatch group before starting the download
                        downloadGroup.enter()
                        
                        // Download the image data
                        let session = URLSession.shared
                        let url = URL(string: photoURLString)!
                        
                        let task = session.dataTask(with: url) { (data, response, error) in
                            defer {
                                // Leave the dispatch group when the download is complete
                                downloadGroup.leave()
                            }
                            
                            if let error = error {
                                print("Error downloading image: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let data = data, let image = UIImage(data: data) else {
                                print("Invalid image data")
                                return
                            }
                            
                            // Convert the image to binary data
                            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                                print("Error converting image to data")
                                return
                            }
                            
                            // Set the image data for the Picture entity
                            pic.imageData = imageData
                        }
                        
                        task.resume()
                    }
                    
                    // Wait for all image downloads to complete
                    downloadGroup.notify(queue: .main) {
                        try? self.dataController.viewContext.save()
                    }
                }
            }
            
            // Create a new annotation
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Add the annotation to the map
            mapView.addAnnotation(annotation)
            
        }
    }
    
    // -MARK: Pin Methods
    
    //to TAP on a pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Check if the selected annotation view is of type MKPinAnnotationView
        if let pinAnnotationView = view as? MKMarkerAnnotationView {
            // Find the selected pin based on the annotation coordinate
            let selectedCoordinate = pinAnnotationView.annotation?.coordinate
            let selectedLatitude = Float(selectedCoordinate?.latitude ?? 0.0)
            let selectedLongitude = Float(selectedCoordinate?.longitude ?? 0.0)
          
            // Fetch the Pin object from Core Data using the selected latitude and longitude
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", selectedLatitude as NSNumber, selectedLongitude as NSNumber)
            
            do {
                let pins = try dataController.viewContext.fetch(fetchRequest)
                if let selectedPin = pins.first {
                    
                    // Call the segue with the specified identifier and pass the selected pin
                    performSegue(withIdentifier: "Album", sender: selectedPin)
                }
            } catch {
                fatalError("Failed to fetch pin: \(error)")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Album" {
            if let selectedPin = sender as? Pin {
                let destinationVC = segue.destination as! PhotoAlbumViewController
                //sends pin to next controller. 
                destinationVC.pin = selectedPin
            }
        }
    }

//    In the collection view controller's collectionView(_:numberOfItemsInSection:) method, return the count of Picture objects associated with the pin:
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return pin.photos?.count ?? 0
//    }
//    In the collection view controller's collectionView(_:cellForItemAt:) method, retrieve the imageData for each Picture object and display it in the collection view cell:
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
//
//        guard let pictures = pin.photos?.allObjects as? [Picture] else {
//            return cell
//        }
//
//        let picture = pictures[indexPath.item]
//        if let imageData = picture.imageData, let image = UIImage(data: imageData) {
//            cell.imageView.image = image
//        }
//
//        return cell
//    }
//
    
    //Links to help:
    //Details:
    //https://docs.google.com/document/d/1j-UIi1jJGuNWKoEjEk09wwYf4ebefnwcVrUYbiHh1MI/pub
    //API:
    //https://www.flickr.com/services/api/
    //requirements:
    //https://review.udacity.com/#!/rubrics/1990/view
    
    //Strat:
    //Build the UI, connect all buttons/logic
    //Build the APIS, make sure they work
    //Test Functionality, Make Core Data model
    //Revise and Repeat/Test
    
    //    Main Screen: The app's main screen typically displays a map view, allowing users to select a location they want to explore. It may also include a search bar or other controls for navigating the map.
    //
    //    Photo Collection Screen: Once a location is selected, the app displays a collection of photos associated with that location. This screen usually shows a grid or list view of thumbnail images. Users can tap on a photo to view it in a larger size or perform additional actions like saving or deleting the photo.
    //
    //    Photo Detail Screen: When a user taps on a photo, a detail screen is shown with a larger view of the photo along with any additional information like the photo's title, description, or tags. This screen may also include buttons or controls for saving, sharing, or deleting the photo.
    
}

//Details: locations and photo albums will be stored in core data
//assume it saves to the pin.
//now find the way to

