//
//  Photo+CoreDataProperties.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/5/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var farmId: Int64
    @NSManaged public var imageData: NSData?
    @NSManaged public var photoId: Int64
    @NSManaged public var secret: String?
    @NSManaged public var serverId: Int64
    @NSManaged public var urlM: String?
    @NSManaged public var createDate: NSDate?
    @NSManaged public var pin: Pin?

}
