//
//  ImageDetailsViewController.swift
//  Virtual Tourist
//
//  Created by Anko Top on 11/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import UIKit

class ImageDetailsViewController: UIViewController {

    // must be set by the prepareForSegue
    var photo: Photo!
    
    @IBOutlet weak var detailImage: UIImageView!
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
       
        self.navigationController?.toolbarHidden = true
        detailImage.image = photo.localImage
        
    }

}
