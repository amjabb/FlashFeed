//
//  SecondViewController.swift
//  NoName
//
//  Created by Amir Jabbari on 11/15/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit
import CloudKit
import Google


extension UIImage {
    var circleMask: UIImage {
        let square = size.width < size.height ? CGSize(width: size.width, height: size.width) : CGSize(width: size.height, height: size.height)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = UIViewContentMode.scaleAspectFill
        imageView.image = self
        imageView.layer.cornerRadius = square.width/2
        imageView.layer.borderColor = UIColor.blue.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = true
        UIGraphicsBeginImageContext(imageView.bounds.size)
        imageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

class SecondViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GIDSignInUIDelegate {

    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBAction func loadPictureButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    
    let imagePicker = UIImagePickerController()
    
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profilePictureView.contentMode = .scaleAspectFit
            profilePictureView.image = pickedImage.circleMask
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func downloadImage(url: URL) {
        print("Download Started")
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil
            else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() { () -> Void in
                self.profilePictureView.image = UIImage(data: data)?.circleMask
                
            }
        }
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        if GIDSignIn.sharedInstance().currentUser.profile.hasImage {
            
            let url = String(describing: GIDSignIn.sharedInstance().currentUser.profile.imageURL(withDimension: 100)!)
            
            if let checkedUrl = URL(string: url) {
                profilePictureView.contentMode = .scaleAspectFit
                downloadImage(url: checkedUrl)
            }
        }
        
//        NotificationCenter.default.addObserver(self,
//                                                         selector: "receiveToggleAuthUINotification:",
//                                                         name: NSNotification.Name(rawValue: "ToggleAuthUINotification"),
//                                                         object: nil)
        
        toggleAuthUI()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    deinit {
//        NotificationCenter.default.removeObserver(self,
//                                                            name: NSNotification.Name(rawValue: "ToggleAuthUINotification"),
//                                                            object: nil)
//    }
    
    func toggleAuthUI() {
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()){
            // Signed in
           userNameLabel.text = GIDSignIn.sharedInstance()?.currentUser?.profile?.name
            print("Logged In")
        } else {
            print("Not logged In")
        }
    }
    
//    @objc func receiveToggleAuthUINotification(notification: NSNotification) {
//        if (notification.name.rawValue == "ToggleAuthUINotification") {
//            self.toggleAuthUI()
//            if notification.userInfo != nil {
//                let userInfo:Dictionary<String,String?> =
//                    notification.userInfo as! Dictionary<String,String?>
//                print(userInfo)
//                self.userNameLabel.text = userInfo["statusText"]!
//            }
//        }
//    }
    
//    var ckUser: CKRecord {
//        get {
//            if _ckUser == nil {
//                _ckUser = CKRecord(recordType: "User")
//            }
//            return _ckUser!
//        }
//        set{
//            _ckUser = newValue
//        }
//    }
//    
//    let date = Date()
//    let calender = NSCalendar.current
//    
//    private var _ckUser: CKRecord? {
//        didSet {
//            let userName = ckUser["userName"] as? String ?? ""
//            let userProfilePicture = ckUser["userProfilePicture"] as? UIImage
//            
//        }
//    }
//    
//    private let database = CKContainer.default().publicCloudDatabase
//    
//    private func iCloudUpdate(){
//        if !(userNameLabel.text?.isEmpty)!{
//            ckUser["userName"] = userNameLabel.text as CKRecordValue?
//            ckUser["userProfilePicture"] = profilePictureView.image as! CKRecordValue?
//            iCloudSaveRecord(recordToSave: ckUser)
//        }
//    }
//    
//    private func iCloudSaveRecord(recordToSave: CKRecord){
//        database.save(recordToSave, completionHandler: { (savedRecord, error) in
//            if error?._code == CKError.serverRecordChanged.rawValue {
//                // optimistic locking failed, ignore
//            } else if error != nil {
//                print(error)
//                //nothing
//            }
//        })
//    }



}

