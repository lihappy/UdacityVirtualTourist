//
//  MapViewController.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/4/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: CoreDataViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        self.mapView.addGestureRecognizer(longPress)
        
        let stack = (UIApplication.shared.delegate as! AppDelegate).stack
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        let pins = fetchedResultsController!.fetchedObjects
        if (pins != nil && pins!.count > 0) {
            var annotations = [MKPointAnnotation]()
            
            for pin in pins! {
                let lat = (pin as! Pin).latitude
                let long = (pin as! Pin).longitude
                
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                annotations.append(annotation)
            }
            
            mapView.addAnnotations(annotations)
        }
        
        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
    
    }
    
    func addAnnotation(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == UIGestureRecognizerState.began) {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate

            mapView.addAnnotation(annotation)
            
            let pin: Pin = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: fetchedResultsController!.managedObjectContext)
            print("created pin \(pin)")
            stack.save()
        }
        
    }


}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Make the annotation be selectable again
        mapView.deselectAnnotation(view.annotation, animated: false)
        
        let photosVC = self.storyboard?.instantiateViewController(withIdentifier: "photosViewController") as! PhotosViewController
        photosVC.annotation = view.annotation
        
        print(view.annotation?.coordinate.latitude ?? 0.0)
        print(view.annotation?.coordinate.longitude ?? 0.0)
        
        // Create Fetch Request
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        fr.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: true)]
        
        let latitudePredicate = NSPredicate(format: "latitude = %@", (view.annotation?.coordinate.latitude)!)
        let longitudePredicate = NSPredicate(format: "longitude = %@", (view.annotation?.coordinate.longitude)!)
        let andPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.and, subpredicates: [latitudePredicate, longitudePredicate])
        fr.predicate = andPredicate

        // Create FetchedResultsController
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Inject it into the notesVC
        photosVC.fetchedResultsController = fc
        
        let pins = fetchedResultsController!.fetchedObjects
        if (pins != nil && pins!.count > 0) {
            let pin = pins![0] as! Pin
            photosVC.pin = pin
            if (pin.photos == nil || (pin.photos?.count)! < 1) {
                FlickrClient.sharedInstance().searchByLocation(pin, self)
            }
        } else {
            print("error. there's no pin")
        }
        
        show(photosVC, sender: true)
    }
    
    
    
}

