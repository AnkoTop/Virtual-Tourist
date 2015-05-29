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

class PhotoAlbumCollectionViewController: UICollectionViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIPopoverPresentationControllerDelegate {
    
    // will be set before segue from the mapView
    var currentLocation: TravelLocation!
    var currentPhoto: Photo!
    var headerImage : UIImage!
    
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    @IBOutlet var photoCollectionView: UICollectionView!
    
    var allowIndividualDelete = false
    
  
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController?.navigationBarHidden = false
        self.setAllowNewCollectionTo(false)
        
        // Fetch the results from coredata
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        
        if fetchedResultsController.fetchedObjects!.count > 0 {
        
            self.handlePhotoDownload()
  
        } else {
            
            self.getNewPhotoCollection(self)
        
        }
    }
    
    
    @IBAction func getNewPhotoCollection(sender: AnyObject?) {
        
        self.setAllowNewCollectionTo(false)
        
        FlickrClient.sharedInstance().getImagesFor(self.currentLocation) {succes, message, error in
            if succes {

                self.handlePhotoDownload()
                
            } else {
                
                self.showImageErrorWith(message)
           
            }
        }
    }


    func handlePhotoDownload() {
  
        if self.fetchedResultsController.fetchedObjects!.count > 0 {
            for photo in self.fetchedResultsController.fetchedObjects as! [Photo] {
                if !photo.downloaded {
                    FlickrClient.sharedInstance().getPhotoFromUrlFor(photo)
                }
            }
            
            self.setAllowNewCollectionTo(true)
            
        } else {
            
            var alert = UIAlertView(title: "No images found", message: "Sorry, we found no (new) images for this location.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
            
        }
    }
    
    
    func setAllowNewCollectionTo(bool: Bool) {
   
        if bool {
            self.newCollectionButton.enabled = true
            self.navigationController?.toolbarHidden = false
            self.allowIndividualDelete = true
            
        } else {
            self.newCollectionButton.enabled = false
            self.navigationController?.toolbarHidden = true
            self.allowIndividualDelete = false
        }
    }
    
    
    func showImageErrorWith(message: String) {
        // show the error
        var alert = UIAlertView(title: "Problem retrieving a collection", message: "Sorry, we encountered an error : \(message)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext {
    
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    //  - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "localFilePath", ascending: true)] //sort old->new
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.currentLocation); // only for the current location
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        return fetchedResultsController
        
        }()
    
    
    //MARK: - popoverdelegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
 
        return .None
    
    }
    
    
    
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
        if photo.downloaded {
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
                    performSegueWithIdentifier(Constants.SegueIdentifier.ShowImageDetails, sender: self) // segue to imagedetails
                }
            }
        }
    }
        
        
    // MARK: - Prepare for Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
       
        switch segue.identifier! {
            case Constants.SegueIdentifier.ShowImageDetails:
                let controller = segue.destinationViewController as! ImageDetailsViewController
                controller.photo = currentPhoto
            case Constants.SegueIdentifier.ShowTags:
                let popoverViewController = segue.destinationViewController as! TagCollectionViewController
                popoverViewController.currentLocation = self.currentLocation
                popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
                popoverViewController.popoverPresentationController!.delegate = self
        default:
            break
        }
    }

    
    func removeFromCollection(gestureRecognizer : UIGestureRecognizer){
        if allowIndividualDelete {
            if let indexPath = self.collectionView?.indexPathForCell(gestureRecognizer.view as! PhotoAlbumUICollectionViewCell) {
                let photoForDelete = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
                sharedContext.deleteObject(photoForDelete)
                CoreDataStackManager.sharedInstance().saveContext()
            }
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


// MARK - extension PhotoAlbumCollectionViewController

extension PhotoAlbumCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        //
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
 
        let changedPhoto = anObject as! Photo
        
        switch type {
            case .Insert:   // image added: show it
                
                dispatch_sync(dispatch_get_main_queue()) {
                    self.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                }
            
            case .Delete:     // image deleted: remove it
    
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
            
            case .Update:   // image updated: refresh it
                
                if changedPhoto.downloaded {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if let cell = self.photoCollectionView.cellForItemAtIndexPath(indexPath!) as? PhotoAlbumUICollectionViewCell {
                            cell.locationImage.image = changedPhoto.localImage!
                            cell.loadImageActivityIndicator.stopAnimating()
                            }
                        }
                
                } else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if let cell = self.photoCollectionView.cellForItemAtIndexPath(indexPath!) as? PhotoAlbumUICollectionViewCell {
                            cell.locationImage.image = UIImage(named: "placeHolderError")
                            cell.loadImageActivityIndicator.stopAnimating()
                        }
                    }
                }
        default:
                return
        }
    }
}
