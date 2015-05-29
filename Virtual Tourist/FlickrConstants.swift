//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Anko Top on 05/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    struct Constants {
        static let BaseSecureUrl = "https://api.flickr.com/services/rest/"
        static let MethodName = "flickr.photos.search"
        static let ApiKey = "ac8c28e52697be4b3265c47a4480efed"
        static let Extras = "url_m"
        static let SafeSearch = "1"
        static let Format = "json"
        static let NoJsonCallback = "1"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingboxHalfHeight = 1.0
        static let PerPage = 24
     }
    
    struct Arguments {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Bbox = "bbox"
        static let SafeSearch = "safe_search"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJsonCallback = "nojsoncallback"
        static let PerPage = "per_page"
    }
    
}