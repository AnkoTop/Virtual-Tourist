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

class TravelLocationViewController: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //restore MapView from last session
        restoreMapRegion(false)
        
        //retrieve SavedCoredata
        fetchedResultsController.performFetch(nil)
        //show the fetched results on the map
        let locations = fetchedResultsController.fetchedObjects as! [TravelLocation]
        for location in locations {
            mapView.addAnnotation(location.annotation)
        }
        
        
        fetchedResultsController.delegate = self
    
        
        // Add longpressrecognizer to the mapView
        let longTap: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "dropPinOnMap:")
        longTap.numberOfTapsRequired = 0
        longTap.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longTap)
        
    }
    
    
    
    // MARK: - Drop pin on map
    
    //let annotation = MKPointAnnotation()
    
    func dropPinOnMap(gestureRecognizer : UIGestureRecognizer) {
        if (gestureRecognizer.state == .Ended) {
            let tapPoint: CGPoint = gestureRecognizer.locationInView(mapView)
            let touchMapCoordinate: CLLocationCoordinate2D = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
                
            var coordinate = mapView.convertPoint(tapPoint, toCoordinateFromView: self.mapView)
        
            var location = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
            var loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
            CLGeocoder().reverseGeocodeLocation(loc, completionHandler: { (placemarks, error) -> Void in
            
                if error == nil {
                
                    // Placemark data includes information such as the country, state, city, and street address associated with the specified coordinate.
                    let placemark = CLPlacemark(placemark: placemarks[0] as! CLPlacemark)
                
                    var subthoroughfare = placemark.subThoroughfare != nil ? placemark.subThoroughfare : ""
                
                    var thoroughfare = placemark.thoroughfare != nil ? placemark.thoroughfare : ""
                
                    var city = placemark.subAdministrativeArea != nil ? placemark.subAdministrativeArea : ""
                    var state = placemark.administrativeArea != nil ? placemark.administrativeArea : ""
                
                    var title = "\(subthoroughfare) \(thoroughfare)"
                    var subTitle = "\(city),\(state)"
                
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = location
                    annotation.title = title
                    annotation.subtitle = subTitle
                 
                    // save to core data
                    let newLocation = TravelLocation(annotation: annotation, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            })
        }
    }
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "TravelLocation")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    // NSFetchedResultControllerDelegate
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            mapView.addAnnotation((anObject as! TravelLocation).annotation)
        case .Delete:
            mapView.removeAnnotation((anObject as! TravelLocation).annotation)
        default:
            println("something other than a delete or insert"  )
        }
    }

    
    // MARK: - Helpers : Save/Restore the zoom level with NSKeyedArchiver
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    func saveMapRegion() {
         let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
        
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
}


// MARK: - extension of the class

extension TravelLocationViewController : MKMapViewDelegate {
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
     }
}

