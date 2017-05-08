//
//  PhotosViewController.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/4/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit
import MapKit

class PhotosViewController: CoreDataViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var annotation: MKAnnotation? = nil
    var pin: Pin? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.annotation != nil {
            self.mapView.addAnnotation(self.annotation!)
            self.mapView.centerCoordinate = self.annotation!.coordinate
        }
    }

    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func getNewCollection(_ sender: Any) {
    }
    

}
