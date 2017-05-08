//
//  CoreDataViewController.swift
//  UdacityVirtualTourist
//
//  Created by Li, Haibo on 5/5/17.
//  Copyright © 2017 Amazon. All rights reserved.
//

import UIKit
import CoreData

class CoreDataViewController: UIViewController {
    
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
            reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
    
    func reloadData() {
        print("reloadData")
    }

}

extension CoreDataViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        print("CoreDataViewController didChange anObject")
        
    }
}
