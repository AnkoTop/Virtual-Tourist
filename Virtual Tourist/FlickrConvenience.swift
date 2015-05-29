//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Anko Top on 09/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension FlickrClient {
    
    
    func getPhotoFromUrlFor(photo: Photo) {
        //Make sure the photo is not deleted in the meantime!
        if !(photo.managedObjectContext == nil) {
            let qos = Int(DISPATCH_QUEUE_PRIORITY_DEFAULT.value)
            dispatch_async(dispatch_get_global_queue(qos, 0)) {
                let imageURL = NSURL(string: photo.remoteFilePath)
                var request: NSURLRequest = NSURLRequest(URL: imageURL!)
                let queue:NSOperationQueue = NSOperationQueue()
                NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler:{ (response: NSURLResponse!, data: NSData!, error: NSError!) -> Void in
                    var err: NSError
                    // this happens on another thread; the phote can be deleted so check
                    if photo.managedObjectContext != nil && !photo.deleted {
                        if error == nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                photo.localImage = UIImage(data: data)
                                photo.downloaded = true
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                        }
                    }
                })
            }
        }
    }
    
  
    
    func getImagesFor(location: TravelLocation, completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        
        //delete all the old ones
        if location.photos != nil{
            var delete : NSArray = location.photos!
            for photo in delete   {
                sharedContext.deleteObject(photo as! NSManagedObject)
                CoreDataStackManager.sharedInstance().saveContext()
            }
        }
        
        //create bbox from the coordinates
        let hW = Constants.BoundingBoxHalfWidth
        let hH = Constants.BoundingboxHalfHeight
        let bbox = "\(location.longitude - hW),\(location.latitude - hH),\(location.longitude + hW),\(location.latitude + hH)"
        // set the methodarguments
        let methodArguments :[String: AnyObject] = [
            Arguments.Method: Constants.MethodName,
            Arguments.ApiKey: Constants.ApiKey,
            Arguments.Bbox: bbox,
            Arguments.SafeSearch: Constants.SafeSearch,
            Arguments.Extras: Constants.Extras,
            Arguments.Format: Constants.Format,
            Arguments.NoJsonCallback: Constants.NoJsonCallback,
            Arguments.PerPage: Constants.PerPage
        ]
        
        getImagesFromFlickrBySearch(location, methodArguments: methodArguments, completionHandler: completionHandler)
        
    }
    
    func getImagesFromFlickrBySearch(location: TravelLocation, methodArguments: [String : AnyObject], completionHandler: (succes:Bool, message: String, error: NSError?) -> Void) {
        
        let task = taskForGetBySearch(methodArguments) { JSONResult, error in
            if let error = error {
                completionHandler(succes: false, message: "Error in Network connection", error: error)
            } else {
                if let photosDictionary = JSONResult.valueForKey("photos") as? [String:AnyObject] {
                
                    if let totalPages = photosDictionary["pages"] as? Int {
                        let pageLimit = min(totalPages, Constants.PerPage)
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit) + 1))
                        self.getImagesFromFlickrBySearchWithPage(location, pageNumber: randomPage, methodArguments: methodArguments, completionHandler: completionHandler)
                    } else {
                        completionHandler(succes: false, message: "Cant find key 'pages' in dictionary", error: error)
                    }
                } else {
                    completionHandler(succes: false, message: "No photos found for this location.", error: error)
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
                                var newPhoto =  Photo(remoteFileName: photo["url_m"] as! String, travelLocation: location, context: self.sharedContext)
                                CoreDataStackManager.sharedInstance().saveContext()
                            }
                            completionHandler(succes: true, message: "", error: error)
                       
                        } else {
                        
                            completionHandler(succes: false, message: "No photos found for this location.", error: error)
                        }
                    } else {
                       completionHandler(succes: false, message: "No photos found for this location.", error: error)
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