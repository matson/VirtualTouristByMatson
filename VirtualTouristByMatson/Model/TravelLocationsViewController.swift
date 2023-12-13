//
//  ViewController.swift
//  VirtualTouristByMatson
//
//  Created by Tracy Adams on 12/12/23.
//

import UIKit
import MapKit


class TravelLocationsViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    //Allows user to drop pins around the world.
    //this will be a screen which the user will be allowed to pinch/zoom
    //state should save
    //Tapping and holding map should add a pin.
    //When pin is tapped, it will navigate to the photo album view associated with pin
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
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
//
