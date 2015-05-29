//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Anko Top on 07/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)


class Photo: NSManagedObject {
    
    //@NSManaged var uuid: String
    @NSManaged var remoteFilePath : String
    @NSManaged var localFilePath : String
    @NSManaged var downloaded : Bool
    @NSManaged var location : TravelLocation
    
    override func willSave() {
        // delete any images belonging to the location when it is deleted
       
        if self.deleted {
            if downloaded {
                FlickrClient.Caches.imageCache.deleteImage(localFilePath)
            }
        }
    }
    
    var localImage: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(localFilePath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: localFilePath)
        }
        
    }
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    // init without downloaded photo
    init(remoteFileName: String, travelLocation: TravelLocation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.remoteFilePath = remoteFileName
        self.localFilePath = "\(NSUUID().UUIDString).jpg"
        self.downloaded = false
        self.location = travelLocation
        
    }

}
