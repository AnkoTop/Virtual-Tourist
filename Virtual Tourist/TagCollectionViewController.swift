//
//  TagCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Anko Top on 11/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import UIKit
import CoreData

class TagCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {

    
    // must be set by segue
    var currentLocation : TravelLocation!
    
    // outlets
    @IBOutlet weak var tagCollectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var keywordText: UITextField!
    @IBOutlet weak var addButton: UIButton!
    
    
    var currentTags = [Tag]()
    var selectedTag : Tag?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        // set delegates
        tagCollectionView.delegate = self
        tagCollectionView.dataSource = self
        keywordText.delegate = self
        
        addButton.setTitleColor(UIColor.grayColor(), forState: .Disabled)
        addButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        deleteButton.setTitleColor(UIColor.grayColor(), forState: .Disabled)
        deleteButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)

    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
       // layout stuff
        deleteButton.enabled = false
        addButton.enabled = false
        tagCollectionView.layer.borderWidth = 1.0
        tagCollectionView.layer.borderColor = UIColor.blackColor().CGColor
        
        
        // Fetch tags from CoreData
        currentTags = fetchAllTags()
       
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func deleteTag(sender: UIButton) {
        
        // delete from currenttags & refresh collection
        var indexPath  = self.tagCollectionView.indexPathsForSelectedItems()[0] as! NSIndexPath
        self.currentTags.removeAtIndex(indexPath.item)
        self.tagCollectionView.reloadData()
    
        // delete from core data
        sharedContext.deleteObject(self.selectedTag!)
        CoreDataStackManager.sharedInstance().saveContext()
        
        deleteButton.enabled = false
        
    }
    
    
    @IBAction func addTag(sender: AnyObject) {
    
        keywordText.resignFirstResponder()
        
        if keywordText.text != "" {
            //add to coredata
            let newTag = Tag(keyword: keywordText.text, travelLocation: currentLocation, context: sharedContext)
            CoreDataStackManager.sharedInstance().saveContext()
            
            // add to currentTags & refresh collection
            currentTags.append(newTag)
            self.tagCollectionView.reloadData()
        
            keywordText.text = ""
        }
    }
    
    
    func setAddTagButton() -> Bool {
        if currentTags.count >= Constants.Limits.maxNumberOfTagsForLocation {
            addButton.enabled = false
            
            var composeAlert = UIAlertController(title: "Max tags reached!", message: "Sorry, you can add max \(Constants.Limits.maxNumberOfTagsForLocation) tags for a location.", preferredStyle: UIAlertControllerStyle.Alert)
            composeAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                // 
                
            }))
            presentViewController(composeAlert, animated: true, completion: nil)
            return false
        } else {
            addButton.enabled = true
            return true
        }
    }

    
    
    // MARK: - TextFieldDelegate
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if setAddTagButton() == true {
            return true
        } else {
            return false
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        keywordText.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
         addButton.enabled = true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        // add the tag
        addTag(self)
        addButton.enabled = false
    }
    
    
    // MARK: - CollectionView Delegate
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
     
        return 1   // only 1 section
    
    }
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return currentTags.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let reuseIdentifier = "tagCell"
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! TagCollectionViewCell
        let tag = self.currentTags[indexPath.item]
        cell.tagLabel.text = tag.keyword
        cell.tagLabel.layer.borderColor = UIColor.blackColor().CGColor
        cell.tagLabel.layer.borderWidth = 1.0
        cell.tagLabel.layer.backgroundColor = UIColor.whiteColor().CGColor

        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.selectedTag = currentTags[indexPath.item]
        deleteButton.enabled = true
        
    }
    
    
    
    // MARK: - Core Data
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    
    func fetchAllTags() -> [Tag] {
        var error: NSError?
        let fetchRequest = NSFetchRequest(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "location == %@", self.currentLocation); // only for the current location

        let results = sharedContext.executeFetchRequest(fetchRequest, error: &error)
        
        // check for errors
        if let error = error {
            var composeAlert = UIAlertController(title: "Error in retrieving tags", message: "Sorry, we encountered this error : \(error)", preferredStyle: UIAlertControllerStyle.Alert)
            composeAlert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                //
                
            }))
            presentViewController(composeAlert, animated: true, completion: nil)
        }
        
        return results as! [Tag]
    }
    


}