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
    
    var dataController: DataController!
    
    //defined to fetch pins
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
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
        let regionRadius: CLLocationDistance = 1000000
        let coordinateRegion = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        
        // Set the initial region of the map
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //ADD a pin
    func addPin(long: Float, lat: Float){
        //create a new context of Pin
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = lat
        pin.longitude = long
        //then save to the context
        try? dataController.viewContext.save()
        
    }
    
    
    //to ADD a pin
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            let lat = Float(coordinate.latitude)
            let long = Float(coordinate.longitude)
            
            //create pin and save to core data
            addPin(long: long, lat: lat)
            
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
            let fetchRequest = createFetchRequest(lat: selectedLatitude, long: selectedLongitude)
            
            do {
                let pins = try context.fetch(fetchRequest)
                
                //this is the pin chosen
                if let selectedPin = pins.first {
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
            
                destinationVC.dataController = dataController
                //send selected pin
                destinationVC.pin = selectedPin
                //send the latitude and longitude
                let location = CLLocation(latitude: CLLocationDegrees(selectedPin.latitude), longitude: CLLocationDegrees(selectedPin.longitude))
                destinationVC.selectedLocation = location
                
            }
            
        }
    }
    
    func createFetchRequest(lat: Float, long: Float) -> NSFetchRequest<Pin> {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", lat as NSNumber, long as NSNumber)
        return fetchRequest
    }
    
}


