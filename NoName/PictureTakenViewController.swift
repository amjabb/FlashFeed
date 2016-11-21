//
//  PictureTakenViewController.swift
//  NoName
//
//  Created by Amir Jabbari on 11/20/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit

class PictureTakenViewController: UITabBarController {

    @IBOutlet weak var pictureTaken: UIImageView!
    
    var picture:UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let pic = picture {
        pictureTaken.image = pic
        }
        //Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
