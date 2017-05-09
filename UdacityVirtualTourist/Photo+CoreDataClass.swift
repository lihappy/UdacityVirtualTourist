//
//  Photo+CoreDataClass.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/5/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(photoId: Int64, farmId: Int64, serverId: Int64, secret: String, url: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.photoId = photoId
            self.farmId = farmId
            self.secret = secret
            self.serverId = serverId
            self.urlM = url
            self.createDate = Date() as NSDate?
        } else {
            fatalError("Unable to find Entity name")
        }
    }

}
