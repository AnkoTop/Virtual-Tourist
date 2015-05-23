//
//  PhotoAlbumCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Anko Top on 07/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import UIKit
import CoreData

let reuseIdentifier = "PhotoAlbumCell"

class PhotoAlbumCollectionViewController: UICollectionViewController, UICollectionViewDataSource ,UICollectionViewDelegateFlowLayout {
    
    // will be set before segue from the mapView
    var location: TravelLocation!
    var currentPhoto: Photo!
    var headerImage : UIImage!

    
    
    @IBOutlet var photoCollectionView: UICollectionView!
    //@IBOutlet weak var imageForCell: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.toolbarHidden = true
        
        // Fetch the results from coredata
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        // check for empty images
        let qos = Int(DISPATCH_QUEUE_PRIORITY_BACKGROUND.value)
        dispatch_async(dispatch_get_global_queue(qos, 0)) {
            for photo in self.location.photos! {
                if photo.localImage == nil {
                    FlickrClient.sharedInstance().getPhotoFromUrlFor(self.location, photo: photo)
                }
            }
        }
      //  println("view will appear # fetched : \(fetchedResultsController.fetchedObjects!.count)")
        if fetchedResultsController.fetchedObjects!.count > 0 {
          self.navigationController?.toolbarHidden = false
        } else {
            FlickrClient.sharedInstance().getImagesForLocation(self.location) {succes, message, error in
                //do what?
            }
        }

       
    }
    
    
    @IBAction func getNewPhotoCollection(sender: UIBarButtonItem) {
        
       FlickrClient.sharedInstance().deleteImagesForLocation(location) {succes, message, error in
            if succes {
                // get a new batch of images
                 FlickrClient.sharedInstance().getImagesForLocation(self.location) {succes, message, error in
                    
                    let qos = Int(DISPATCH_QUEUE_PRIORITY_HIGH.value)
                    dispatch_async(dispatch_get_global_queue(qos, 0)) {
                        for photo in self.location.photos! {
                            if photo.localImage == nil {
                                FlickrClient.sharedInstance().getPhotoFromUrlFor(self.location, photo: photo)                            }
                        }
                    }
                }
            } else {
                println("that's not good")
            }
        }
   
    }
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    //  - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creation", ascending: true)] //sort old->new
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location); // only for the current location
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    
    
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        
        return 1
        
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        return sectionInfo.numberOfObjects
        
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumUICollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        // check if we have an image or have to show a placeholder
        if photo.localImage != nil {
            //cell.locationImage.image = UIImage(data: photo.image!)
            cell.locationImage.image = photo.localImage
            cell.loadImageActivityIndicator.stopAnimating()
        } else {
            cell.locationImage.image = UIImage(named: "placeHolder")
            cell.loadImageActivityIndicator.startAnimating()
        }
        
        //add tap recognizer to show details
        let singleTap = UITapGestureRecognizer(target: self, action: Selector("showImageDetails:"))
        
        singleTap.numberOfTapsRequired = 1
        cell.addGestureRecognizer(singleTap)
        
        //add doubletap recognizer to delete
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector("removeFromCollection:"))
        doubleTap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(doubleTap)
        
        singleTap.requireGestureRecognizerToFail(doubleTap)
  
        return cell
    }
    
    func showImageDetails (gestureRecognizer : UIGestureRecognizer) {
        if let indexPath = self.collectionView?.indexPathForCell(gestureRecognizer.view as! PhotoAlbumUICollectionViewCell) {
            if let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo {
                currentPhoto = photo
                if photo.localImage != nil {
                    performSegueWithIdentifier(Constants.SegueIdentifier.showImageDetails, sender: self) // segue to imagedetails
                }
            }
        }
    }
        
        
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == Constants.SegueIdentifier.showImageDetails {
            let controller = segue.destinationViewController as! ImageDetailsViewController
             controller.photo = currentPhoto    
        }
    }

    
    func removeFromCollection(gestureRecognizer : UIGestureRecognizer){

        if let indexPath = self.collectionView?.indexPathForCell(gestureRecognizer.view as! PhotoAlbumUICollectionViewCell) {
            let photoForDelete = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            sharedContext.deleteObject(photoForDelete)
            CoreDataStackManager.sharedInstance().saveContext()
        }
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath)
        -> UICollectionReusableView {
            
            var header: PhotoAlbumHeaderCollectionReusableView?
            
            if kind == UICollectionElementKindSectionHeader {
                header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "PhotoAlbumHeader", forIndexPath: indexPath)
                    as? PhotoAlbumHeaderCollectionReusableView
                
                header?.sectionHeaderImage.image = headerImage
            }
            return header!
    }

       
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Set Item properties
        // fit 3 foto's horizontal and adjust vertical size to 4:3 ratio
        let spaceHorizontal = self.collectionView!.frame.width
        var size = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        size.width = spaceHorizontal / 3
        size.height = 3 * (size.width/4)
        
        return size
    }
    
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
          var size = (collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize
        size.width = self.collectionView!.frame.width
        size.height = self.collectionView!.frame.height/10
        return size
    }

}




extension PhotoAlbumCollectionViewController: NSFetchedResultsControllerDelegate {
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
       // println("WillChangeContent")
    }

    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
            
            switch type {
                case .Insert:
                    println("insert section")
                case .Delete:
                    println("delete section")
                default:
                    return
            }
    }

    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let changedPhoto = anObject as! Photo
        switch type {
            case .Insert:
                // image added: show it
                dispatch_sync(dispatch_get_main_queue()) {
                   self.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                 }
            case .Delete:
                // image deleted: remove it
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
            case .Update:
                // image updated: refresh it
                if changedPhoto.localImage != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        if let cell = self.photoCollectionView.cellForItemAtIndexPath(indexPath!) as? PhotoAlbumUICollectionViewCell {
                            cell.locationImage.image = changedPhoto.localImage!
                            cell.loadImageActivityIndicator.stopAnimating()
                        }
                    }
                }
            
            //case .Move:
                // not implemented
                
            default:
                return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
 //       println("DidChangeContent")
   }
    
}
