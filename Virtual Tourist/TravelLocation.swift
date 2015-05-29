//
//  TravelLocation.swift
//  Virtual Tourist
//
//  Created by Anko Top on 04/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData
import MapKit


@objc(TravelLocation)

class TravelLocation: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var title: String?
    @NSManaged var subTitle : String?
    @NSManaged var photos : [Photo]?
    
    
    // computed property; no need to store it in core data
    var annotation : MKPointAnnotationForTravelLocation {
        get {
            let newAnnotation = MKPointAnnotationForTravelLocation()
            newAnnotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
            newAnnotation.title = title
            newAnnotation.subtitle = subTitle
            newAnnotation.forTravelLocation = self
            return newAnnotation
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init (annotation: MKPointAnnotation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("TravelLocation", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.latitude = annotation.coordinate.latitude
        self.longitude = annotation.coordinate.longitude
        self.title = annotation.title
        self.subTitle = annotation.subtitle
    }
    
}
