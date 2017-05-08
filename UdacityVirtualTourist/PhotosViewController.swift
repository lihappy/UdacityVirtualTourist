//
//  PhotosViewController.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/4/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotosViewController: CoreDataViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectioinView: UICollectionView!
    
    var annotation: MKAnnotation? = nil
    var pin: Pin? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectioinView.delegate = self
        self.collectioinView.dataSource = self

        if self.annotation != nil {
            self.mapView.addAnnotation(self.annotation!)
            self.mapView.centerCoordinate = self.annotation!.coordinate
        }
        
        self.setFlowLayout()
    }

    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func getNewCollection(_ sender: Any) {
    }
    
    func setFlowLayout() {
        let orientation = UIApplication.shared.statusBarOrientation
        let itemCountInRow: CGFloat = orientation.isPortrait ? 3.0 : 6.0;
        let space: CGFloat = 3.0
        let dimension = ((orientation.isPortrait ? view.frame.size.width : view.frame.size.height) - ((itemCountInRow - 1) * space)) / itemCountInRow
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        self.executeSearch()
//        self.collectioinView.reloadData()
        print("did change")
        self.collectioinView.reloadData()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("will change")
    }
    
//    override func reloadData() {
//        super.reloadData()
//        guard self.collectioinView != nil else {
//            return
//        }
//        self.collectioinView.reloadData()
//    }

}

extension PhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //delete
    }
    
}

extension PhotosViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! photoCollectionViewCell
        
        // Configure the cell
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        let mediaUrl = photo.urlM!
        if (photo.imageData == nil) {
            if let imageData = try? Data(contentsOf: URL(string: mediaUrl)!) {
                photo.imageData = imageData as NSData?
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: imageData)
                }
            } else {
                print("Image does not exist at \(mediaUrl)")
            }
        } else {
            cell.imageView.image = UIImage(data: photo.imageData as! Data)
        }
        return cell
    }
}

