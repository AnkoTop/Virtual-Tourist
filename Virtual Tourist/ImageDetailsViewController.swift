//
//  ImageDetailsViewController.swift
//  Virtual Tourist
//
//  Created by Anko Top on 11/05/15.
//  Copyright (c) 2015 Anko Top. All rights reserved.
//

import UIKit

class ImageDetailsViewController: UIViewController {

    var photo: Photo!
    @IBOutlet weak var detailImage: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
       
        self.navigationController?.toolbarHidden = true
        detailImage.image = photo.localImage
        //detailImage.image = UIImage(data: imageData)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
