//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Anko Top on 09/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData

extension FlickrClient {
    
    
    func getPhotoFromUrl(photo: Photo) {
        //Make sure the photo is not deleted in the meantime!
        if !(photo.managedObjectContext == nil) {
            let imageURL = NSURL(string: photo.localFilePath)
            if let imageData = NSData(contentsOfURL: imageURL!) {
                if !(photo.managedObjectContext == nil) {
                    photo.image = imageData
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }
        
    }
    
    func deleteImagesForLocation (location: TravelLocation, completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        for photo in location.photos! {
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        completionHandler(succes: true, message: "all photo's are deleted", error: nil)
    }
    
    
    func getImagesForLocation(location: TravelLocation, completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        //create bbox from the coordinates
        let hW = Constants.BoundingBoxHalfWidth
        let hH = Constants.BoundingboxHalfHeight
        let bbox = "\(location.longitude - hW),\(location.latitude - hH),\(location.longitude + hW),\(location.latitude + hH)"
        // set the methodarguments
        let methodArguments :[String: AnyObject] = [
            Arguments.method: Constants.methodName,
            Arguments.apiKey: Constants.apiKey,
            Arguments.bbox: bbox,
            Arguments.safeSearch: Constants.safeSearch,
            Arguments.extras: Constants.extras,
            Arguments.format: Constants.format,
            Arguments.noJsonCallback: Constants.noJsonCallback,
            Arguments.perPage: Constants.perPage
        ]
        
        getImagesFromFlickrBySearch(location, methodArguments: methodArguments, completionHandler: completionHandler)
        
    }
    
    func getImagesFromFlickrBySearch(location: TravelLocation, methodArguments: [String : AnyObject], completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        
        let task = taskForGetBySearch(methodArguments) { JSONResult, error in
            if let error = error {
                completionHandler(succes: false, message: "Error in Network connection", error: error)
            } else {
               if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
                    //println("photodictionary: \(photosDictionary)")
                
                    if let totalPages = photosDictionary["pages"] as? Int {
                        let pageLimit = min(totalPages, Constants.perPage)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit) + 1))
                        self.getImagesFromFlickrBySearchWithPage(location, pageNumber: randomPage, methodArguments: methodArguments, completionHandler: completionHandler)
                    } else {
                        completionHandler(succes: false, message: "Cant find key 'pages' in dictionary", error: error)
                        println("Cant find key 'pages' in \(photosDictionary)")
                    }
                }
            }
        }
    }
    
    
    func getImagesFromFlickrBySearchWithPage(location: TravelLocation, pageNumber: Int, methodArguments: [String : AnyObject], completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        
        let task = self.taskForGetBySearchWithPage(methodArguments, pageNumber: pageNumber) { JSONResult, error in
            if let error = error {
                completionHandler(succes: false, message: "Error in Network connection", error: error)
            } else {
                if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                        
                            for photo in photosArray {
                                let imageUrlString = photo["url_m"] as? String
                                
                                var newPhoto =  Photo(localFileName: photo["url_m"] as! String, travelLocation: location, context: self.sharedContext)
                                CoreDataStackManager.sharedInstance().saveContext()
                            
                            }
                         completionHandler(succes: true, message: "", error: error)
                        } else {
                        
                        completionHandler(succes: false, message: "No photos found", error: error)
                        }
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Shared Context for CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
}