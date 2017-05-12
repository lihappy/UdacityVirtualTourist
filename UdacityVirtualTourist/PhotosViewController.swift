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
    @IBOutlet weak var collectionView: UICollectionView!
    
    var annotation: MKAnnotation? = nil
    var pin: Pin? = nil
    var enableNewCollectionButton: Bool? = true
    
    let activityIndicator = UIActivityIndicatorView.init(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        if self.annotation != nil {
            self.mapView.addAnnotation(self.annotation!)
            self.mapView.centerCoordinate = self.annotation!.coordinate
        }
        
        self.newCollectionButton.isEnabled = enableNewCollectionButton!
        
        self.setFlowLayout()
        
        if !enableNewCollectionButton! {
            self.activityIndicator.center = self.view.center
            self.activityIndicator.hidesWhenStopped = true
            self.view.addSubview(self.activityIndicator)
            self.view.bringSubview(toFront: self.activityIndicator)
            self.activityIndicator.startAnimating()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PhotosViewController.dealPhotosNotification),
                                               name: NSNotification.Name(rawValue: Constants.Notification.GetPhotosNotification),
                                               object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.GetPhotosNotification), object: nil)
    }
    
    func dealPhotosNotification(_ notification: Notification) {
        
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
        
        guard let userInfo = notification.userInfo else {
            return
        }

        guard let status = userInfo[Constants.Notification.GetPhotoStatusKey] as? GetPhotoStatus else {
            return
        }
        
        DispatchQueue.main.async {
            if GetPhotoStatus.succeed == status {
                self.reloadData()
                self.stack.save()
            } else if (GetPhotoStatus.fail == status) {
                guard let errorMsg = userInfo[Constants.Notification.ErrorKey] as? String else {
                    return
                }
                showSimpleErrorAlert(_message: errorMsg, _sender: self)
            } else if (GetPhotoStatus.noPhotos == status){
                showSimpleErrorAlert(_message: Constants.NoPhotosMsg, _sender: self)
            }
            
            self.newCollectionButton.isEnabled = true
        }
        
    }


    @IBAction func goBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func getNewCollection(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.newCollectionButton.isEnabled = false
        
        pin?.photos = nil
        FlickrClient.sharedInstance().searchByLocation(pin!, stack.backgroundContext)
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
        print("did change")
    }
    
    override func reloadData() {
        guard self.collectionView != nil else {
            return
        }
        self.collectionView.reloadData()
    }
    

}

extension PhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //delete
        let photo = self.fetchedResultsController?.object(at: indexPath) as! Photo
        pin?.removeFromPhotos(photo)
        self.reloadData()
        stack.save()
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
            DispatchQueue.global().async {
                if let imageData = try? Data(contentsOf: URL(string: mediaUrl)!) {
                    photo.imageData = imageData as NSData?
                    DispatchQueue.main.async {
                        cell.imageView.image = UIImage(data: imageData)
                    }
                } else {
                    print("Image does not exist at \(mediaUrl)")
                }
            }
            
        } else {
            cell.imageView.image = UIImage(data: photo.imageData as! Data)
        }
        return cell
    }
}

