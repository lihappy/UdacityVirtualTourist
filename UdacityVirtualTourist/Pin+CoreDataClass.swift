//
//  Pin+CoreDataClass.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/5/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {

    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
            self.createDate = Date() as NSDate?
        } else {
            fatalError("Unable to find Entity name")
        }
    }
}
