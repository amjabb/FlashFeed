//
//  PostInputViewController.swift
//  NoName
//
//  Created by Amir Jabbari on 11/15/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit
import CloudKit
import Google
import AVFoundation

class PostInputViewController: UIViewController, UITextViewDelegate,
UINavigationControllerDelegate {
    
    @IBOutlet weak var postTextView: UITextView!
    
    @IBAction func postButton(_ sender: Any) {
        iCloudUpdate()
        performSegue(withIdentifier: "Posted Text", sender: sender)
        //self.navigationController?.tabBarController?.selectedIndex = 0
    }
    
   // @IBOutlet weak var captureImageView: UIImageView!
    @IBOutlet weak var postImageView: UIView!
    
    var pictureIfTaken: UIImage! { didSet{ performSegue(withIdentifier: "Picture Taken", sender: nil) }}
    
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        if let videoConnection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo) {
            //postImageView.isHidden = true
            stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: { (sampleBuffer, error) -> Void in
                // ...
                // Process the image data (sampleBuffer) here to get an image file we can put in our captureImageView
                if sampleBuffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let dataProvider = CGDataProvider(data: imageData as! CFData)
                    let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
                    let image = UIImage(cgImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.right)
                    self.pictureIfTaken = image
                    
                    // ...
                    // Add the image to captureImageView here.
                    //                    let imageView = UIImageView(image: image)
                    //                    imageView.frame = self.postImageView.bounds
                    //                    self.view.addSubview(imageView)
                    
                }
            })

            // ...
            // Code for photo capture goes here...
        }
    }
    
    //This function is used for the segmented control views 
    //are hidden and showed based on the tab of the segmented control that is selected
    @IBAction func indexChanged(_ sender: UISegmentedControl) {
        
        switch segmentedControl.selectedSegmentIndex
        {
        case 0:
            postTextView.isHidden = false
            postImageView.isHidden = true
        case 1:
            postTextView.isHidden = true
            postImageView.isHidden = false
            
        default:
            break;
        }
        
    }
    
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    var session: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
//  MARK - Navigation
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Post"
        postImageView.isHidden = true
        
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        
        postTextView.delegate = self;
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        session = AVCaptureSession()
        session!.sessionPreset = AVCaptureSessionPresetPhoto
        let backCamera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        var error: NSError?
        var input: AVCaptureDeviceInput!
        do {
            input = try AVCaptureDeviceInput(device: backCamera)
        } catch let error1 as NSError {
            error = error1
            input = nil
            print(error!.localizedDescription)
        }
        if error == nil && session!.canAddInput(input) {
            session!.addInput(input)
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if session!.canAddOutput(stillImageOutput) {
                session!.addOutput(stillImageOutput)
                videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
//                videoPreviewLayer!.frame = postImageView.bounds
                videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
                //videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                postImageView.layer.addSublayer(videoPreviewLayer!)
                
                session!.startRunning()
                // ...
                // Configure the Live Preview here...
            }
            // ...
            // The remainder of the session setup will go here...
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        videoPreviewLayer!.frame = postImageView.bounds
        //videoPreviewLayer!.frame = CGRect(x: 0, y: 0, width: 414, height: 375)
        //postImageView.contentMode = UIViewContentMode.scaleAspectFill
        
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
    
//  MARK - Database 
    
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
        
        //        if postImageView.image != nil {
        //
        //            let data = UIImagePNGRepresentation(postImageView.image!); // UIImage -> NSData, see also UIImageJPEGRepresentation
        //            let url = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(NSUUID().uuidString+".dat")
        //            do {
        //                try data?.write(to: url!, options: [])
        //            } catch let e as NSError {
        //                print("Error! \(e)");
        //                return
        //            }
        //
        //        cktextPost["image"] = CKAsset(fileURL: url!) as CKRecordValue
        ////            do { try FileManager.default.removeItem(at: url!) }
        ////            catch let e { print("Error deleting temp file: \(e)") }
        //        }
        if !postTextView.text.isEmpty {
            cktextPost["text"] = postTextView.text as CKRecordValue?
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
    }

//  MARK - segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let barController = segue.destination as? UITabBarController {
            
            if let navigationController = barController.viewControllers?[0] as? UINavigationController{
                if let destination = navigationController.topViewController as? FirstViewController{
                    if segue.identifier == "Posted Text" {
                        barController.selectedIndex = 0
                        sleep(3)
                    }
                    
                }
            }
        }
        if let destination = segue.destination as? PictureTakenViewController {
            if segue.identifier == "Picture Taken" {
                destination.picture = pictureIfTaken //Does not work
                destination.text = postTextView.text
            }
        }
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    
}


