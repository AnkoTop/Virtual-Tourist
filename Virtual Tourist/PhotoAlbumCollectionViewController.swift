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
    var headerImage : UIImage!
    
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet weak var imageForCell: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //println("Photo: viewDidLoad")
        //println("current location: \(location)")
        
        // Fetch the results from coredata
        // if there is no album available get pictures from flickr
       
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        self.navigationController?.navigationBarHidden = false
        self.navigationController?.toolbarHidden = true
        //println("Photo: viewWillAppear")
        
        // Fetch the results from coredata
        fetchedResultsController.performFetch(nil)
        fetchedResultsController.delegate = self
        // check for empty images
        let qos = Int(DISPATCH_QUEUE_PRIORITY_BACKGROUND.value)
        dispatch_async(dispatch_get_global_queue(qos, 0)) {
         for photo in self.location.photos! {
            if photo.image == nil {
                 FlickrClient.sharedInstance().getPhotoFromUrl(photo)
     //            println("nsdata empty: get the picture")
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
        
       FlickrClient.sharedInstance().renewImagesForLocation(location) {succes, message, error in
                                   //do what?
            if succes {
                                   // println("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
                FlickrClient.sharedInstance().getImagesForLocation(self.location) {succes, message, error in
                    //println("I'm back")
                    let qos = Int(DISPATCH_QUEUE_PRIORITY_HIGH.value)
                    dispatch_async(dispatch_get_global_queue(qos, 0)) {
                        for photo in self.location.photos! {
                            if photo.image == nil {
                                FlickrClient.sharedInstance().getPhotoFromUrl(photo)
                                //println("nsdata empty: get the picture")
                            }
                        }
                    }

                }
            } else {println("sucks")}
        
        println(message)
    }
   
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creation", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.location);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
        }()
    
    
    
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        let sectionInfo = self.fetchedResultsController.sections![section] as!
        NSFetchedResultsSectionInfo
        
        println(sectionInfo.numberOfObjects)
        
        return sectionInfo.numberOfObjects
        
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
    
        // Configure the cell
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoAlbumUICollectionViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        // check if we have an image or have to show a placeholder
        if photo.image != nil {
            cell.locationImage.image = UIImage(data: photo.image!)
            cell.loadImageActivityIndicator.stopAnimating()
        } else {
            cell.locationImage.image = UIImage(named: "placeHolder")
            cell.loadImageActivityIndicator.startAnimating()
//            let qos = Int(DISPATCH_QUEUE_PRIORITY_BACKGROUND.value)
//            dispatch_async(dispatch_get_global_queue(qos, 0)) {
//                FlickrClient.sharedInstance().getPhotoFromUrl(photo)
//            }
        }
        
        
        
        //add doubletap recognizer to delete
        let doubleTap = UITapGestureRecognizer(target: self, action: Selector("removeFromCollection:"))
        doubleTap.numberOfTapsRequired = 2
        cell.addGestureRecognizer(doubleTap)
        
        //println("cellinsert for \(photo.creation)")
        //println(fetchedResultsController.fetchedObjects!.count)

        return cell
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

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Set Item properties
        // fit 3 foto's horizontal
        let spaceHorizontal = self.collectionView!.frame.width
        var size = (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        size.width = spaceHorizontal / 3
        //size.height = 9 * (size.width/16)
        size.height = 3 * (size.width/4)
        
        return size
    }
    
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
          var size = (collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize
        size.width = self.collectionView!.frame.width
        size.height = self.collectionView!.frame.height/10
   //     println("headersize : \(size)")
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
                 // new pictore added: show it
               //  println("photo \(changedPhoto.creation) inserted")
               //  println(fetchedResultsController.fetchedObjects!.count)

                 //NSThread.sleepForTimeInterval(1.0)
                dispatch_sync(dispatch_get_main_queue()) {
                   self.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                 }
//                let qos = Int(QOS_CLASS_BACKGROUND.value)
//                dispatch_async(dispatch_get_global_queue(qos, 0)) {
//                    FlickrClient.sharedInstance().getPhotoFromUrl(changedPhoto)
//                }
        
            
            case .Delete:
      //          println("photo \(changedPhoto.creation) deleted")
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
     //           println(fetchedResultsController.fetchedObjects!.count)
//                if fetchedResultsController.fetchedObjects!.count == 0 {
//                    //let qos = Int(QOS_CLASS_USER_INITIATED.value)
//                    //dispatch_async(dispatch_get_global_queue(qos, 0)) {
//                    FlickrClient.sharedInstance().getImagesForLocation(self.location) {succes, message, error in
//                        //do what?
//                        println("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
//                    }
//                   // }
//                }
            case .Update:
          //      println("photo \(changedPhoto.creation) updated")
                if changedPhoto.image != nil {
//                    //println("update the image")
                    dispatch_async(dispatch_get_main_queue()) {
                    if let cell = self.photoCollectionView.cellForItemAtIndexPath(indexPath!) as? PhotoAlbumUICollectionViewCell
                    {cell.locationImage.image = UIImage(data: changedPhoto.image!)
                        cell.loadImageActivityIndicator.stopAnimating()}
                    }
            }
            
            case .Move:
                println("photo moved")
                
            default:
                return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
 //       println("DidChangeContent")
//       dispatch_async(dispatch_get_main_queue()) {
//
//        self.photoCollectionView.reloadData()
//        }
    }
    
}
