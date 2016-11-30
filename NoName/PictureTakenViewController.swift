//
//  PictureTakenViewController.swift
//  NoName
//
//  Created by Amir Jabbari on 11/20/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit
import Google
import CloudKit

class PictureTakenViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var pictureTaken: UIImageView!
    
    @IBOutlet weak var captionText: UITextView!

//    @IBOutlet weak var postButton: UIButton!
//    
//    @IBAction func postButton(_ sender: Any) {
//        iCloudUpdate()
//        performSegue(withIdentifier: "Posted Text", sender: sender)
//    }
    
    var picture:UIImage?
    var text: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if picture != nil {
            pictureTaken.image = picture
            captionText.text = text
            
        }
        captionText.delegate = self
        //Do any additional setup after loading the view.
    }

    @IBOutlet weak var post: UIButton!
    @IBAction func post(_ sender: Any) {
        iCloudUpdate()
        performSegue(withIdentifier: "Posted Text", sender: sender)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    //This is a delegate function of textview that shows and hides the keyboard when the user
    //presses the return key
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    var cktextPost: CKRecord {
        get {
            if _cktextPost == nil {
                _cktextPost = CKRecord(recordType: "TextPost")
            }
            return _cktextPost!
        }
        set{
            _cktextPost = newValue
        }
    }
    
    let date = Date()
    let calender = NSCalendar.current
    
    private var _cktextPost: CKRecord? {
        didSet {
            let postText = cktextPost["text"] as? String ?? ""
            let postTextDate = cktextPost["datePosted"] as? Date
            //let user = CKReference(record: ckUser, action: CKReferenceAction.none)
            
        }
    }
    
    private var profilePicture: NSURL!
    private let database = CKContainer.default().publicCloudDatabase
    
    private func iCloudUpdate(){
        // if !postTextView.text.isEmpty{
        
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()){
            // Signed in
            cktextPost["userID"] = GIDSignIn.sharedInstance()?.currentUser?.userID as CKRecordValue?
            cktextPost["userName"] = GIDSignIn.sharedInstance()?.currentUser?.profile?.name as CKRecordValue?
            print("Logged In")
        } else {
            print("Not logged In")
        }
        
                if pictureTaken.image != nil {
                    do{
                cktextPost["image"] = try CKAsset(image: pictureTaken.image!)
                        print("Picture converted to URL")
                    }catch{
                        print("Error creating assets", error)
                    }
        }
        if !captionText.text.isEmpty {
            cktextPost["text"] = captionText.text as CKRecordValue?
        }
        cktextPost["datePosted"] = date as CKRecordValue?
        
        //Here I need to create a profile picture attribute of text post
        //the profile picture attribute will hold a String which is the URL
        //of the of the picture. This sets the profile picture attribute of
        //the textPost to be the profilepictures url. Now we need a function
        //that will update this url in all posts by that user once the user changes
        //there profile picture.
        let userName = GIDSignIn.sharedInstance()?.currentUser?.profile?.name
        let predicate = NSPredicate(format: "userName == %@", userName!)
        let query = CKQuery(recordType: "User", predicate: predicate)
        //query.sortDescriptors = [NSSortDescriptor(key: "datePosted", ascending: false)]
        cktextPost["profilePicture"] = nil
        database.perform(query, inZoneWith: nil) { (records, error) in
            if records != nil {
                DispatchQueue.main.async {
                    //print(records?[0]["profilePicture"] as! String)
                    let pictureURL = NSURL(string: records?[0]["profilePicture"] as! String)
                    if pictureURL != nil {
                        self.profilePicture = pictureURL
                        self.cktextPost["profilePicture"] = pictureURL as? CKRecordValue
                    }
                    
                }
            }
        }
        iCloudSaveRecord(recordToSave: cktextPost)
        //  }
    }
    
    
    private func iCloudSaveRecord(recordToSave: CKRecord){
        database.save(recordToSave, completionHandler: { (savedRecord, error) in
            if error?._code == CKError.serverRecordChanged.rawValue {
                // optimistic locking failed, ignore
            } else if error != nil {
                print(error!)
                //nothing
            }
        })
        print("SAVED")
    }
    
    //  MARK - segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let barController = segue.destination as? UITabBarController {
            
            if let navigationController = barController.viewControllers?[0] as? UINavigationController{
                if let destination = navigationController.topViewController as? FirstViewController{
                    if segue.identifier == "Posted Text" {
                        //barController.selectedIndex = 0
                        sleep(3)
                    }
                    
                }
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
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
