//
//  TouristLocationViewController.swift
//  Virtual Tourist
//
//  Created by Anko Top on 04/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class TravelLocationViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    var selectedLocation: TravelLocation!
    var currentPinView: MKAnnotationView!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locations = [TravelLocation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        //restore MapView from last session
        restoreMapRegion(false)
    
        //retrieve Saved Coredata and show results on the map
        locations = fetchAllTravelLocations()
        for location in locations {
            mapView.addAnnotation(location.annotation)
        }
        
        // Add longpressrecognizer to the mapView
        let longTap = UILongPressGestureRecognizer(target: self, action: "dropPinOnMap:")
        longTap.numberOfTapsRequired = 0
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)
        
        
        //default maptype is Standard
        mapView.mapType = .Standard
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        //always hide bars
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.toolbarHidden = true
        
        
    }
    
    @IBAction func toggleMapType() {
        //set maptype to the next value
        switch mapView.mapType {
            case .Standard:
                mapView.mapType = .Satellite
            case .Satellite :
                mapView.mapType = .Hybrid
        case .Hybrid :
                mapView.mapType = .Standard
        }
    }
    
    // MARK: - Drop pin on map
    
    func dropPinOnMap(longtapRecognizer : UIGestureRecognizer) {
    
        if (longtapRecognizer.state) == .Began {
            let tapPoint: CGPoint = longtapRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
                
            var coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: self.mapView)
        var location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
            CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks, error) -> Void in
            
                if error == nil {
                    let placemark = CLPlacemark(placemark: placemarks[0] as! CLPlacemark)
                    var city = placemark.subAdministrativeArea != nil ? placemark.subAdministrativeArea : ""
                    var state = placemark.administrativeArea != nil ? placemark.administrativeArea : ""
                    var country = placemark.country != nil ? placemark.country : ""
                    var title = "\(city) - \(state)"
                    var subTitle = "\(country)"
                    if city == "" {
                        if state == "" {
                            title = ""
                        } else {
                            title = "\(state)"
                        }
                    } else {
                        if state == "" {
                            title = "\(city)"
                        }
                    }
                    
                
                    var annotation = MKPointAnnotationForTravelLocation()
                    annotation.coordinate = location.coordinate
                    annotation.title = title
                    annotation.subtitle = subTitle
                    
                    //save to core data
                    let newLocation = TravelLocation(annotation: annotation, context: self.sharedContext)
                    self.locations.append(newLocation)
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    annotation.forTravelLocation = newLocation
                    self.mapView.addAnnotation(annotation)

                    // get a set of images for this location
                    FlickrClient.sharedInstance().getImagesForLocation(newLocation) {succes, message, error in
                        // ????
                    }
                }
            })
        }
    }
    
    
    // MARK: - MapviewDelegate
    
    // When the region changes by zooming or scrolling: save the new map state
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseIdForPin = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseIdForPin) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdForPin)
            pinView!.canShowCallout = true
            pinView!.draggable = true
            pinView!.pinColor = .Purple
    
            //add a delete button on the left side
            let buttonDelete = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
            buttonDelete.setBackgroundImage(UIImage(named: "trash"), forState: .Normal)
            buttonDelete.tintColor = UIColor.clearColor()
            pinView!.leftCalloutAccessoryView = buttonDelete
            //and the information button on the right
            let buttonInformation = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
            pinView!.rightCalloutAccessoryView = buttonInformation
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView

    }

    //Handle the buttonactions of the pin annotation
    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if annotationView.draggable == true {
            annotationView.draggable = false
        }
        
        for location in locations {
            if (annotationView.annotation as! MKPointAnnotationForTravelLocation).forTravelLocation == location {
                selectedLocation = location
                break
            }
        }
        self.currentPinView = annotationView
        
        if control == annotationView.leftCalloutAccessoryView { // delete button tapped
            sharedContext.deleteObject(selectedLocation)
            CoreDataStackManager.sharedInstance().saveContext()
            self.mapView.removeAnnotation(annotationView.annotation)
        } else if control == annotationView.rightCalloutAccessoryView { // info button tapped
            
            performSegueWithIdentifier(Constants.SegueIdentifier.showPhotoAlbum , sender: self) // segue to the collection view
        }
    }
    
    
    // Mark: - Prepare the segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
       if segue.identifier == Constants.SegueIdentifier.showPhotoAlbum {
            let controller = segue.destinationViewController as! PhotoAlbumCollectionViewController
        
            //send a snapshot from the selected location as a headerimage for the collectionview
            controller.headerImage = takeSnapshotOfLocation()
            
            // set the location for the photos to be shown
            controller.currentLocation = selectedLocation
        }
    }
    
    
    // helper: - take snapshot of part of the map with the selected pin on it
    func takeSnapshotOfLocation() -> UIImage {
        
        let contextSize = CGSize(width: self.view.frame.width, height: self.view.frame.height/10)
        
        UIGraphicsBeginImageContextWithOptions(contextSize, false, 1.0)
            var xpos = mapView.frame.origin.x
            var ypos = mapView.frame.origin.y
            var rectangle = mapView.frame
            let yAdjust = currentPinView.frame.origin.y
            rectangle.origin.y = -yAdjust
            self.view.drawViewHierarchyInRect(rectangle, afterScreenUpdates: true)
            var snapshot : UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return snapshot
    }
    
    
    // MARK: - Core Data: use the basic version (the fetchedresultcontroller has no added value for TravelLocations)
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func fetchAllTravelLocations() -> [TravelLocation] {
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "TravelLocation")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
        
        if let error = error {
            // XXXX  ADD MESSAGE
            println("Error in fectchAllTravelLocations(): \(error)")
        }
        return results as! [TravelLocation]
    }

   
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == .Ending {
            view.draggable = false
            println("draggin no more...")
            //save to core data
//            let newLocation = TravelLocation(annotation: annotation, context: self.sharedContext)
//            self.locations.append(newLocation)
//            CoreDataStackManager.sharedInstance().saveContext()
//            
//            // get a set of images for this location
//            FlickrClient.sharedInstance().getImagesForLocation(newLocation) {succes, message, error in
//                // ????
//            }

        }
    }
    
   
    // MARK: - NSKeyedArchiver : Save/Restore the map settings
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let latitudeDelta = "latitudeDelta"
        static let longitudeDelta = "longitudeDelta"
    }
    
    func saveMapRegion() {
         let dictionary = [
            Keys.latitude : mapView.region.center.latitude,
            Keys.longitude : mapView.region.center.longitude,
            Keys.latitudeDelta : mapView.region.span.latitudeDelta,
            Keys.longitudeDelta : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            let longitude = regionDictionary[Keys.longitude] as! CLLocationDegrees
            let latitude = regionDictionary[Keys.latitude] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary[Keys.longitudeDelta] as! CLLocationDegrees
            let latitudeDelta = regionDictionary[Keys.latitudeDelta] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
        
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}
