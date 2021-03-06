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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation))
        self.mapView.addGestureRecognizer(longPress)
        
        // Restore center and zoom level for map
        self.restoreMapview(self.mapView)
        
        // Add annotations
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
    }
    
    func restoreMapview(_ mapview: MKMapView) {
        guard let centerLat = UserDefaults.standard.value(forKey: Constants.Map.CenterLat) as? Double else {
            return
        }
        
        guard let centerLon = UserDefaults.standard.value(forKey: Constants.Map.CenterLon) as? Double else {
            return
        }
        
        guard let spanLat = UserDefaults.standard.value(forKey: Constants.Map.SpanLat) as? Double else {
            return
        }
        
        guard let spanLon = UserDefaults.standard.value(forKey: Constants.Map.SpanLon) as? Double else {
            return
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let span = MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapview.region = region
        
    }
    
    func addAnnotation(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == UIGestureRecognizerState.began) {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate

            mapView.addAnnotation(annotation)
            
            let _ = Pin(latitude: coordinate.latitude, longitude: coordinate.longitude, context: fetchedResultsController!.managedObjectContext)
            
            stack.save()
        }
        
    }


}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: Constants.Map.CenterLat)
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: Constants.Map.CenterLon)
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: Constants.Map.SpanLat)
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: Constants.Map.SpanLon)
    }
    
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
        
        let currentPin = self.searchPinByLatLon((view.annotation?.coordinate.latitude)!, (view.annotation?.coordinate.longitude)!)
        guard (currentPin != nil) else {
            return
        }
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: false)]
        
        let predicate = NSPredicate(format: "pin = %@", currentPin!)
        fr.predicate = predicate
        
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        photosVC.fetchedResultsController = fc
        
        photosVC.pin = currentPin
        if (currentPin!.photos == nil || (currentPin!.photos?.count)! < 1) {
            photosVC.enableNewCollectionButton = false
            FlickrClient.sharedInstance().searchByLocation(currentPin!, self.stack.backgroundContext)
        }
        
        show(photosVC, sender: true)
    }
    
    func searchPinByLatLon(_ latitude: Double, _ longitude: Double) -> Pin? {
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fr.sortDescriptors = [NSSortDescriptor(key: "createDate", ascending: true)]
        let pinPredicate = NSPredicate(format: "latitude = %lf AND longitude = %lf", latitude, longitude)
        fr.predicate = pinPredicate
        
        let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try frc.performFetch()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        guard let pins = frc.fetchedObjects else {
            return nil
        }
        
        guard pins.count > 0 else {
            return nil
        }
        
        return pins[0] as? Pin
    }
    
    
    
}

