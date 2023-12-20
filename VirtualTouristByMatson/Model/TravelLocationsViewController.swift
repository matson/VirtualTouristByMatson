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
                        
                        print("got the data though might have not saved correctly.")
                        
                        let picture = Picture(context: self.dataController.viewContext)
                        
                        // Construct the photo URL using the properties of the photo object
                        let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                        
                        picture.pin = pin
                        
                        // Enter the dispatch group before starting the download
                        downloadGroup.enter()
                        
                        // Download the image data from the URL
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
                            picture.imageData = imageData
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
    
    var pinImageData: [Data] = []
    //this is for testing since we cannot save the imageData in coreData.
    
    //to TAP on a pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Assuming you have a reference to your Core Data managed object context
        let context = dataController.viewContext
        // Check if the selected annotation view is of type MKPinAnnotationView
        if let pinAnnotationView = view as? MKMarkerAnnotationView {
            
            print("got the pin")
            // Find the selected pin based on the annotation coordinate
            let selectedCoordinate = pinAnnotationView.annotation?.coordinate
            let selectedLatitude = Float(selectedCoordinate?.latitude ?? 0.0)
            let selectedLongitude = Float(selectedCoordinate?.longitude ?? 0.0)
            
            // Fetch the Pin object from Core Data using the selected latitude and longitude
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", selectedLatitude as NSNumber, selectedLongitude as NSNumber)
            print("have a pin lat and long")
            do {
                let pins = try context.fetch(fetchRequest)
                var imageDataArray: [Data] = []
                if let selectedPin = pins.first {
                    
                    //if the pin does NOT have downloaded Data
                    if selectedPin.photo?.count == 0 {
                        print("I should be in here")
                        FlickrClient.getPhotos(lat: selectedLatitude, long: selectedLongitude) { response, error, success in
                            if success {
                                // Access the photo array
                                let photos = response!.photos.photo
                                
                                // Create a dispatch group to wait for all image downloads to complete
                                let downloadGroup = DispatchGroup()
                                
                                // Iterate over each photo object
                                for photo in photos {
                                    // Construct the photo URL using the properties of the photo object
                                    let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                                    
                                    // Enter the dispatch group before starting the download
                                    downloadGroup.enter()
                                    
                                    //let picture = Picture(context: self.dataController.viewContext)
                                    
                                    //pin to picture relationship
                                    //picture.pin = selectedPin
                                    
                                    // Download the image data from the URL
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
                                    
                                        imageDataArray.append(imageData)
                                        
                                    }
                                    
                                    task.resume()
                                }
                                downloadGroup.notify(queue: .main) {
                                    //try? self.dataController.viewContext.save()
                                    // Pass the fetched imageData to the next view controller
                                    if let selectedPin = pins.first {
                                        if !imageDataArray.isEmpty {
                                            self.pinImageData = imageDataArray
                                        }
                                        self.performSegue(withIdentifier: "Album", sender: selectedPin)
                                    }
                                }
                            }
                        }
                        // Pin does not have any downloaded images
                        // Call the Flickr API and download images for the pin
                        // Save the downloaded images to Core Data
                        
                        // After saving, fetch the images again from Core Data
                        
                        // Access the imageData property of the first picture
                        //                        if let pictures = selectedPin.photo?.allObjects as? [Picture] {
                        //                            // Access the imageData property of the first picture
                        //                            imageData = pictures.first?.imageData
                        //                        }
                    } else {
                        //if it DOES
                        if let pictures = selectedPin.photo?.allObjects as? [Picture] {
                            // Access the imageData property of the first picture
                            //pinImageData = pictures.first?.imageData
                        }
                        performSegue(withIdentifier: "Album", sender: selectedPin)
                    }
                }
            } catch {
                fatalError("Failed to fetch pin: \(error)")
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Album" {
            if let selectedPin = sender as? Pin {
                print("got into the segue")
                let destinationVC = segue.destination as! PhotoAlbumViewController
                //sends pin to next controller.
                destinationVC.pin = selectedPin
                // Pass the imageData to the next view controller
                destinationVC.imageData = pinImageData
                
            }
        }
    }
    
    
    func downLoad(){
        
    }
    
}


