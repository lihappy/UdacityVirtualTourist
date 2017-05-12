//
//  Constants.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/5/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit

enum GetPhotoStatus {
    case fail
    case succeed
    case noPhotos
}

struct Constants {
    
    static let NoPhotosMsg = "No photos"
    
    // MARK: Notification
    struct Notification {
        static let ErrorKey = "ErrorKey"
        static let GetPhotoStatusKey = "GetPhotoStatusKey"
        static let GetPhotosNotification = "GetPhotosNotification"
    }
    
    // MARK: Map
    struct Map {
        static let CenterLat = "centerLat"
        static let CenterLon = "centerLon"
        static let SpanLat = "spanLat"
        static let SpanLon = "spanLon"
    }
    
    // MARK: Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        
        static let imageCount = 15
    }
    
    // MARK: Flickr Parameter Keys
    struct FlickrParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
    }
    
    // MARK: Flickr Parameter Values
    struct FlickrParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "ef3aaf2cf8f4dc71cf909cbf8c69794b"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
    }
    
    // MARK: Flickr Response Keys
    struct FlickrResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
        
        static let Farm = "farm"
        static let Server = "server"
        static let Id = "id"
        static let Secret = "secret"
    }
    
    // MARK: Flickr Response Values
    struct FlickrResponseValues {
        static let OKStatus = "ok"
    }

}
