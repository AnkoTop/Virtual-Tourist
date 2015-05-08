//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Anko Top on 05/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation
import CoreData

class FlickrClient: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func getImagesForLocation(location: TravelLocation) {
        println("in getImages function")
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
        getImagesFromFlickrBySearch(location, methodArguments: methodArguments)
        
    }
    
    func getImagesFromFlickrBySearch(location: TravelLocation, methodArguments: [String : AnyObject]) {
        
        let session = NSURLSession.sharedSession()
        let urlString = Constants.baseSecureUrl + escapedParameters(methodArguments)
        println("url : \(urlString)")
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                println("Could not complete the request \(error)")
            } else {
                
                var parsingError: NSError? = nil
                let parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError) as! NSDictionary
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                    println("photodictionary: \(photosDictionary)")
                    
//                    if let totalPages = photosDictionary["pages"] as? Int {
//                        
//                        /* Flickr API - will only return up the 4000 images (100 per page * 40 page max) */
//                        let pageLimit = min(totalPages, 40)
//                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit) + 1))
//                        //self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
//                    
//                    } else {
//                        println("Cant find key 'pages' in \(photosDictionary)")
//                    }
                    // check how many photos there are
                    var totalPhotosVal = 0
                    if let totalPhotos = photosDictionary["total"] as? String {
                        totalPhotosVal = (totalPhotos as NSString).integerValue
                    }
                    if totalPhotosVal > 0 {
                        if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {
                            for photo in photosArray {
                                println(photo["url_m"])
                                let imageUrlString = photo["url_m"] as? String
                                let imageURL = NSURL(string: imageUrlString!)
                                
                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    
                                    var newPhoto =  Photo(localFileName: photo["url_m"] as! String, imageForLoc:imageData ,travelLocation: location, context: self.sharedContext)
                                    CoreDataStackManager.sharedInstance().saveContext()
                                println(newPhoto)
                                }
                            }
                            
                        }
                        
                    }

                    
                    
                } else {
                    println("Cant find key 'photos' in \(parsedResult)")
                }
            }
        }
        
        task.resume()
    }

    
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }

    // MARK: - Shared Context for CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }


}
