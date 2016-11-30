//
//  FirstViewController.swift
//  NoName
//
//  Created by Amir Jabbari on 11/15/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit
import CloudKit
import NotificationCenter
import Google

//  MARK - CKRecord Extention used to place incoming post that is pushed in from the icloud subscription.
extension CKRecord {
    var datePosted: String {
        return self["datePosted"] as? String ?? ""
    }
}

@IBDesignable
class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    

//  MARK - Deprecated + button on top left to control post type selection.
    //    @IBAction func pickPostType(_ sender: AnyObject) {
    //        let pvc = storyboard?.instantiateViewController(withIdentifier: "popOverController") as! PopOverViewController
    //        pvc.preferredContentSize = CGSize(width: 200, height: 100)
    //        pvc.modalPresentationStyle = .popover
    //
    //        let popoverMenuViewController = pvc.popoverPresentationController
    //        popoverMenuViewController?.permittedArrowDirections = .any
    //        popoverMenuViewController?.delegate = self
    //        popoverMenuViewController?.barButtonItem = sender as? UIBarButtonItem
    //        //popoverMenuViewController?.sourceView = sender as! UIView
    //        popoverMenuViewController?.sourceRect = CGRect(
    //            x: 50,
    //            y: 100,
    //            width: 1,
    //            height: 1)
    //        present(
    //            pvc,
    //            animated: true,
    //            completion: nil)
    //
    //    }
    
    
    var allTextPosts = [CKRecord]()  { didSet { tableView.reloadData() }} //Array where all the text posts will be kept.
    var allUsers = [CKRecord]()  { didSet { tableView.reloadData() } }
    
//  MARK - Navigation view lifecycle to perform icloud and subscription services in this case we are
    //fetching posts by querying the database and using push notifications to automatically
    //update the content viewed
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchAllTextPosts()
        fetchAllUsers()
        iCloudSubscribeToTextPosts()
        UIApplication.shared.applicationIconBadgeNumber = 0 //Sets icon badge to zero once table view is loaded
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        iCloudUnsubscribeToTextPosts()
    }
    
    //View did load method fires when all outlets are set and the page is ready to be viewed
    //Tableview delegate and dataSource methods set to self indicate that delegate functions
    //in code should be executed. Google sign in delegate is also set to self so that 
    //user data can be accessed.
    override func viewDidLoad() {
        super.viewDidLoad()
        //fetchAllTextPosts()
        tableView.delegate      =   self
        tableView.dataSource    =   self
        GIDSignIn.sharedInstance().uiDelegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        self.title = "FlashFeed"
    }
    
    
//  MARK: Database
    fileprivate let database = CKContainer.default().publicCloudDatabase
    
    //Fetch all posts from CloudKit, since all posts are type Textpost we can query all
    //of them by creating a CKQuery object and passing in the record type. The sort 
    //descriptor indicated the format in which the data should be presented.
    //The query is then performed and the records are put into the allTextPosts array.
    func fetchAllTextPosts() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "TextPost", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "datePosted", ascending: false)]
        database.perform(query, inZoneWith: nil) { (records, error) in
            if records != nil {
                DispatchQueue.main.async {
                    self.allTextPosts = records!
                }
            }
        }
    }
    
    func fetchAllUsers() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let query = CKQuery(recordType: "User", predicate: predicate)
        //query.sortDescriptors = [NSSortDescriptor(key: "datePosted", ascending: false)]
        database.perform(query, inZoneWith: nil) { (records, error) in
            if records != nil {
                DispatchQueue.main.async {
                    self.allUsers = records!
                }
            }
        }
    }
    
    
//  MARK: Subscription - Update feed on new post
    // When a new post is added by a user we want the post
    //to automatically be pusehd to all the other users that need to see it
    fileprivate let subscriptionID = "All Text Post Creations"
    fileprivate var cloudKitObserver: NSObjectProtocol?
    
    //CKQuerySubscription allows us to continuously monitor the icloud
    //database when a certain event occurs in this case we would like to query
    //the database every time a new record is created.
    fileprivate func iCloudSubscribeToTextPosts() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKQuerySubscription(
            recordType: "TextPost",
            predicate: predicate,
            subscriptionID: self.subscriptionID,
            options: .firesOnRecordCreation
        )
        
        //Creating a notification info objects lets us pass parameters to our 
        //CKQuery subscription such as whether out application should have badges
        //or what the content of the Alert Body should be when a new post is entered.
        let info = CKNotificationInfo()
        info.alertBody = "New Post!"
        info.shouldBadge = true
        subscription.notificationInfo = info
        
        //The subscription can be performed on the database in the followign way.
        database.save(subscription, completionHandler: { (savedSubscription, error) in
            if error?._code == CKError.serverRejectedRequest.rawValue {
                // ignore
            } else if error != nil {
                // report
            }
        })
        //We can add an observer so that our application is ready for notifications
        //and we can handle the notification such as what screen it opens to or what
        //we want the user to see in this method.
        cloudKitObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "iCloudRemoteNotificationReceived"),
            object: nil,
            queue: OperationQueue.main,
            using: { notification in
                if let ckqn = notification.userInfo?["Notification"] as? CKQueryNotification {
                    self.iCloudHandleSubscriptionNotification(ckqn)
                }
        }
        )
    }
    
    //This is called in the viewdidDisapear method and removes the observer that
    //was watching for the push notifications and delete it from the database
    fileprivate func iCloudUnsubscribeToTextPosts() {
        if let observer = cloudKitObserver {
            NotificationCenter.default.removeObserver(observer)
            cloudKitObserver = nil
        }
        database.delete(withSubscriptionID: self.subscriptionID) { (subscription, error) in
            // handle it
        }
    }
    
    //This method is called when a new post notification is received by the observer
    //in this case we need to query the database and add the new post in the requested
    //order in this case the order we need is by dateposted descending.
    fileprivate func iCloudHandleSubscriptionNotification(_ ckqn: CKQueryNotification)
    {
        if ckqn.subscriptionID == self.subscriptionID {
            if let recordID = ckqn.recordID {
                switch ckqn.queryNotificationReason {
                case .recordCreated:
                    database.fetch(withRecordID: recordID) { (record, error) in
                        if record != nil {
                            DispatchQueue.main.async {
                                self.allTextPosts = (self.allTextPosts + [record!]).sorted {
                                    return $0.datePosted < $1.datePosted
                                }
                            }
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    


//  MARK - Loading profile Pictures
    //Get Data from URL allows us to go to a URL and return a Data type which is then converted
    //to a UIImage
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    var profilePic: UIImage!
    
    //This function downloads the image by converting the url passed in to NSData which can be 
    //downloaded as a UIImage this happens asynchronous to the main queue because it might take
    //a while to download large files
    func downloadImage(url: URL) -> UIImage {
        print("Download Started")
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil
                else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            print("Download Finished")
            DispatchQueue.main.async() { () -> Void in
               self.profilePic = UIImage(data: data)?.circleMask
            }
            
        }
        if profilePic != nil {
            return profilePic
        } else {
            return UIImage(named: "NoProfilePicture" )!
        }
    }
    
    
//    MARK - TableView operations
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTextPosts.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TextPostView = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TextPostView
        cell.profilePicture.image = UIImage(named: "NoProfilePicture")
        let profilePicture : String? = allTextPosts[indexPath.row]["profilePicture"] as! String? ?? nil
        let datePosted = allTextPosts[indexPath.row]["datePosted"] as? Date ?? Date()
        let timePassed = getTimepassed(datePosted: datePosted)
        let userName = allTextPosts[indexPath.row]["userName"] as? String
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()){
            cell.userNameLabel.text = allTextPosts[indexPath.row]["userName"] as? String
            
        } else {
            print("Not logged In")
        }
        
        // The profile picture needs to show up for each cell to show the picture of the corresponding user
        // but also it needs to be able to change if the user chooses to change his or her profile picture
        // so for every picture that we load there has to be a correlation between the person who posted
        // the post and the picture itself. For each cell we have to query all the users and find the one who
        // posted that post and load that users profile picture. We can do this by getting the image URL from
        //the users profile and downloading the picture from that. The alternative is that we associate a picture URL
        //with every post maybe if we can associate this URL from the user record then if the user record changes
        //then all the posts from that user will as well.
//            let predicate = NSPredicate(format: "userName == %@", userName!)
//            let query = CKQuery(recordType: "User", predicate: predicate)
//            //query.sortDescriptors = [NSSortDescriptor(key: "datePosted", ascending: false)]
//            database.perform(query, inZoneWith: nil) { (records, error) in
//                if records != nil {
//                    DispatchQueue.main.async {
//                        //print(records?[0]["profilePicture"] as! String)
//                        let pictureURL = NSURL(string: records?[0]["profilePicture"] as! String)
//                                                    if pictureURL != nil {
//                                                        cell.profilePicture.image = self.downloadImage(url: pictureURL as! URL)
//                                                        if records?[0]["userName"] as! String != userName! {
//                                                        }
//                                                    }
//                    }
//                }
//            }
        if allTextPosts[indexPath.row]["image"] != nil {
            var img = allTextPosts[indexPath.row]["image"] as? CKAsset
            cell.postImage.image = UIImage(contentsOfFile: (img?.fileURL.path)!)?.imageResize(sizeChange: CGSize(width: 375, height: 375))
        } else {
            cell.postImage.image = nil
            //cell.postImage.isHidden = true
        }
        
        if profilePicture != nil {
        cell.profilePicture.image = self.downloadImage(url:  NSURL(string: (profilePicture!)) as! URL)
        }

        cell.textPostLabel.text = allTextPosts[indexPath.row]["text"] as? String
        cell.hoursAgoLabel.text = timePassed
        
        return cell
        
    }
    
    //This function calculates the time interval between the time that it was posted passed in
    // as a parameter and the current date, which is found by using a Date object.
    // This function then returns the text that includes how long ago the post was posted.
    func getTimepassed(datePosted:Date)->String{
        let date = Date()
        let calendar = NSCalendar.current
        let minuteFromPost = calendar.dateComponents([.minute], from: datePosted, to: date).minute
        let hourFromPost = calendar.dateComponents([.hour], from: datePosted, to: date).hour
        let daysFromPost = calendar.dateComponents([.day], from: datePosted, to: date).day
        var timePassed : String
        if minuteFromPost! < 60 {
            timePassed = String(describing: minuteFromPost!) + " minutes ago"
        } else if hourFromPost! < 24 {
            timePassed = String(describing: hourFromPost!) + " hours ago"
        } else {
            timePassed = String(describing: daysFromPost!) + " days ago"
        }
        return timePassed
    }
    
    
    
//  MARK - swipe right to delete
    // The followig three functions enable the user to swipe right on the post and delete it
    // once the user clicks the delete icon a verification menu will be shown where the user 
    //will verify that they would like to delete the post.
    var deleteTextPostIndexPath: NSIndexPath? = nil
    
    //This is one of tableviews delegate methods that enables editing styles for each cell
    //in this case we can specify that if the editing style is delete we would like to perform 
    //certain functions such as verifying the delete
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            deleteTextPostIndexPath = indexPath as NSIndexPath?
            let textPostToDelete = String(describing: allTextPosts[indexPath.row])
            confirmDelete(textPost: textPostToDelete)
            
            
        }
    }
    
    //This function uses a UIAlertController to show the user two options either to confirm the delete
    //or cancel the menu. 
    func confirmDelete(textPost: String) {
        let alert = UIAlertController(title: "Delete Post", message: "Are you sure you want to permanently delete this post?", preferredStyle: .actionSheet)
        
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeletePlanet)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelDeletePlanet)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        // Support display in iPad
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.size.width / 2.0, y: self.view.bounds.size.height / 2.0,width: 1.0,height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //If the delete is confirmed the delete the post from the database and delete the corresponding rows
    func handleDeletePlanet(alertAction: UIAlertAction!) -> Void {
        if let indexPath = deleteTextPostIndexPath {
            tableView.beginUpdates()
            
            database.delete(withRecordID: allTextPosts[indexPath.row].recordID, completionHandler: { (recordID, error) in
                //Do Nothing
            })
            tableView.deleteRows(at: [indexPath as IndexPath], with: .automatic)
            allTextPosts.remove(at: indexPath.row)
            // Note that indexPath is wrapped in an array:  [indexPath]
            
            deleteTextPostIndexPath = nil
            
            tableView.endUpdates()
        }
    }
    
    func cancelDeletePlanet(alertAction: UIAlertAction!) {
        deleteTextPostIndexPath = nil
    }
    
    
    
    
}


extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}

