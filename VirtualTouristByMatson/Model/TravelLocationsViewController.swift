//
//  ViewController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/12/23.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    
    //Singleton code
    var dataController: DataController {
        return DataController.shared
    }
    
    //defined to fetch pins
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    //var latitude: Float = 0.00
    //var longitude: Float = 0.00
    
    //to fetch pins:
    fileprivate func setUpFetchedResultsController() {
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do{
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
        
        mapView.delegate = self
        
        setUpMap()
        
        // Add a long press gesture recognizer to the MapView
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        
        //show saved/existing pins
        getPins()
        
        
    }
    // MARK: Helper Functions
    
    func getPins(){
        
        // Fetch the saved pins from Core Data using the controller
        guard let pins = fetchedResultsController.fetchedObjects else {
            return
        }
        
        // Add the fetched pins as annotations on the map
        for pin in pins {
            
            let latitude = pin.value(forKey: "latitude") as? Float ?? 0.0
            let longitude = pin.value(forKey: "longitude") as? Float ?? 0.0
            
            let coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude), longitude: CLLocationDegrees(longitude))
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            mapView.addAnnotation(annotation)
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
    
    //ADD a pin
    func addPin(long: Float, lat: Float) -> Pin {
        //create a new context of Pin
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = lat
        pin.longitude = long
        //then save to the context
        try? dataController.viewContext.save()
        return pin
    }
    
    
    //to ADD a pin
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let lat = Float(coordinate.latitude)
            let long = Float(coordinate.longitude)
            
            let pin = addPin(long: long, lat: lat)
            
            FlickrClient.getPhotos(lat: lat, long: long) { response, error, success in
                if success {
                    // Access the photo array
                    let photos = response!.photos.photo
                    
                    // Create a dispatch group to wait for all image downloads to complete
                    let downloadGroup = DispatchGroup()
                    
                    // Iterate over each photo object
                    for photo in photos {
                        
                        let picture = Picture(context: self.dataController.viewContext)
                        
                        // Construct the photo URL using the properties of the photo object
                        let photoURLString = "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg"
                        
                        //associate the image with the pin
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
                    //tested to see if it was saving correctly to context.  It is.
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
        //send the latitude and longitude points over
        //to place on the map
        let context = dataController.viewContext
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
                let pins = try context.fetch(fetchRequest)
                
                //this is the pin chosen
                if let selectedPin = pins.first {
                    
                    //if the pin does NOT have downloaded Data
                    if selectedPin.photo?.count == 0 {
                        print("never been downloaded")
                        self.performSegue(withIdentifier: "Album", sender: selectedPin)
                        
                        
                    } else {
                        print("has been downloaded")
                        
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
                let destinationVC = segue.destination as! PhotoAlbumViewController
                
                //send through singleton datacontroller
                destinationVC.dataController = dataController
                //send selected pin
                destinationVC.pin = selectedPin
                //send the latitude and longitude
                let location = CLLocation(latitude: CLLocationDegrees(selectedPin.latitude), longitude: CLLocationDegrees(selectedPin.longitude))
                destinationVC.selectedLocation = location
                
            }
            
        }
    }
    
    
    func downLoad(){
        
    }
    
}


