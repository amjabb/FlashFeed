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

//This extension extends UIImage therfore any functions or attributes defined here can be used by
//any UIImage object.
extension UIImage {
    //The attribute of type UIImage makes a square picture circle and adds a border to the picture.
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

//This is the users profile page currently it shows a picture as well as the users name in a label, it also includes
//a button which enables the user to change there profile picture from pictures in there library. This view should 
//be different depending on whether the user is viewing there own profile to when other people are viewing the users profile.
class SecondViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, GIDSignInUIDelegate {
    
    
    @IBOutlet weak var profilePictureView: UIImageView!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    //This button sets the imagePickers source type to the library and presents
    //the library on the screen.
    @IBAction func loadPictureButton(_ sender: Any) {
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    
//  MARK - Pick image from Library
    let imagePicker = UIImagePickerController()
    
    //Image picker delegate function is called which receives selected picture and set the existing profile picture
    //to be that image. NOTE: This function does not yet save the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            profilePictureView.contentMode = .scaleAspectFit
            profilePictureView.image = pickedImage.circleMask
        }
        
        dismiss(animated: true, completion: nil)
    }
    
//  MARK - Download image from URL
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
    
//  MARK - Navigation
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
        
        toggleAuthUI()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
//  MARK - Google AUTH extras
    //Check whether the user is logged in this function is public
    func toggleAuthUI() {
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()){
            // Signed in
            userNameLabel.text = GIDSignIn.sharedInstance()?.currentUser?.profile?.name
            print("Logged In")
        } else {
            print("Not logged In")
        }
    }
    
    
}

