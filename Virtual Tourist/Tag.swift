//
//  Tag.swift
//  Virtual Tourist
//
//  Created by Anko Top on 23/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData

@objc(Tag)

class Tag : NSManagedObject {
    
    @NSManaged var keyword : String
    @NSManaged var location : TravelLocation
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // full init
    init(keyword: String, travelLocation: TravelLocation, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Tag", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        self.keyword = keyword
        self.location = travelLocation
    }
}
