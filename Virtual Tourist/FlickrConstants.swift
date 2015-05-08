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
        static let baseSecureUrl = "https://api.flickr.com/services/rest/"
        static let methodName = "flickr.photos.search"
        static let apiKey = "PUT API KEY HERE!"
        static let extras = "url_m"
        static let safeSearch = "1"
        static let format = "json"
        static let noJsonCallback = "1"
        static let BoundingBoxHalfWidth = 1.0
        static let BoundingboxHalfHeight = 1.0
        static let perPage = 24
     }
    
    struct Arguments {
        static let method = "method"
        static let apiKey = "api_key"
        static let bbox = "bbox"
        static let safeSearch = "safe_search"
        static let extras = "extras"
        static let format = "format"
        static let noJsonCallback = "nojsoncallback"
        static let perPage = "per_page"
    }
    
}