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
    
    @NSManaged var creation : NSDate
    @NSManaged var remoteFilePath : String
    @NSManaged var localFilePath : String?
    @NSManaged var location : TravelLocation
    
    override func willSave() {

        if self.deleted {
            if localFilePath != nil {
                FlickrClient.Caches.imageCache.deleteImage(localFilePath!)
            }
        }
    }
    
    var localImage: UIImage? {
        
        get {
            
            return FlickrClient.Caches.imageCache.imageWithIdentifier(localFilePath)
        }
        
        set {
            
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: localFilePath!)
        }
        
    }
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // full init
    init(remoteFileName: String, localFilename: String, travelLocation: TravelLocation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        creation = NSDate()
        remoteFilePath = remoteFileName
        localFilePath = localFilename
        location = travelLocation
        
    }
    
    // init without downloaded photo
    init(remoteFileName: String, travelLocation: TravelLocation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        creation = NSDate()
        remoteFilePath = remoteFileName
        
        // make a unique key for the image
        let locationIdentifier = String(stringInterpolationSegment: travelLocation.latitude) + String(stringInterpolationSegment: travelLocation.longitude)
        var indexOfSlash = remoteFilePath.rangeOfString("/", options: .BackwardsSearch)?.startIndex
        localFilePath =  locationIdentifier + remoteFilePath.substringFromIndex(advance(indexOfSlash!, 1))

        location = travelLocation
        
    }

}
