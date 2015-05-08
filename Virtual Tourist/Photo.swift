//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Anko Top on 07/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)


class Photo: NSManagedObject {
    
    @NSManaged var localFilePath : String
    @NSManaged var image : NSData
    @NSManaged var location : TravelLocation
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(localFileName: String, imageForLoc: NSData, travelLocation: TravelLocation, context: NSManagedObjectContext){
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        localFilePath = localFileName
        image = imageForLoc
        location = travelLocation
        
    }
    
    // manage the filehandling here so we can always change the way we store images
    
    func deleteLocalPhotoFile() {
        // TO DO: delete the file from the directory
    }
    
    
    
}
