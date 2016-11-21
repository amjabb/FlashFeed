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

//MARK - CKRecord Extention used to place incoming post that is pushed in from the icloud subscription.
extension CKRecord {
    var datePosted: String {
        return self["datePosted"] as? String ?? ""
    }
}

@IBDesignable
class FirstViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, GIDSignInUIDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK - Deprectaed + button on top left to control post type selection.
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
    
    var allTextPosts = [CKRecord]()  { didSet { tableView.reloadData() } }
    
    //MARK - Navigation view lifecycle to perform icloud and subscription services
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.applicationIconBadgeNumber = 0
        fetchAllTextPosts()
        iCloudSubscribeToTextPosts()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        iCloudUnsubscribeToTextPosts()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAllTextPosts()
        tableView.delegate      =   self
        tableView.dataSource    =   self
        GIDSignIn.sharedInstance().uiDelegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        self.title = "FlashFeed"
    }
    
    
    // MARK: Database
    fileprivate let database = CKContainer.default().publicCloudDatabase
    
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
    
    
    // MARK: Subscription
    
    fileprivate let subscriptionID = "All Text Post Creations"
    fileprivate var cloudKitObserver: NSObjectProtocol?
    
    fileprivate func iCloudSubscribeToTextPosts() {
        let predicate = NSPredicate(format: "TRUEPREDICATE")
        let subscription = CKQuerySubscription(
            recordType: "TextPost",
            predicate: predicate,
            subscriptionID: self.subscriptionID,
            options: .firesOnRecordCreation
        )
        let info = CKNotificationInfo()
        
        info.alertBody = "New Post!"
        info.shouldBadge = true
        
        subscription.notificationInfo = info
        
        // subscription.notificationInfo = ...
        database.save(subscription, completionHandler: { (savedSubscription, error) in
            if error?._code == CKError.serverRejectedRequest.rawValue {
                // ignore
            } else if error != nil {
                // report
            }
        })
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
    
    fileprivate func iCloudUnsubscribeToTextPosts() {
        // we forgot to stop listening to the radio station in the lecture demo!
        // here's how we do that ...
        if let observer = cloudKitObserver {
            NotificationCenter.default.removeObserver(observer)
            cloudKitObserver = nil
        }
        database.delete(withSubscriptionID: self.subscriptionID) { (subscription, error) in
            // handle it
        }
    }
    
    
    
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
    
    
    
    
    //MARK - TableView operations
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTextPosts.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:TextPostView = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TextPostView
        
        let datePosted = allTextPosts[indexPath.row]["datePosted"] as? Date ?? Date()
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
        
        if (GIDSignIn.sharedInstance().hasAuthInKeychain()){
            cell.userNameLabel.text = allTextPosts[indexPath.row]["userName"] as? String
            
        } else {
            print("Not logged In")
        }
        //let hour = calendar.component(.hour, from: date as Date)
        //cell.postImage.removeFromSuperview()
        var File : CKAsset? = allTextPosts[indexPath.row]["image"] as! CKAsset?
        if let file = File {
            if let data = NSData(contentsOf: file.fileURL) {
                cell.postImage.image = UIImage(data: data as Data)
            }
        } else {
            cell.postImage.image = nil
        }
        
        //  cell.postImage.image = allTextPosts[indexPath.row]["image"] as? UIImage
        if cell.postImage.image != nil {
            print("This cell doesn't have an image")
        }
        cell.textPostLabel.text = allTextPosts[indexPath.row]["text"] as? String
        cell.hoursAgoLabel.text = timePassed
        
        return cell
        
    }
    
    
    // MARK - swipe right to delete
    var deleteTextPostIndexPath: NSIndexPath? = nil
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            deleteTextPostIndexPath = indexPath as NSIndexPath?
            let textPostToDelete = String(describing: allTextPosts[indexPath.row])
            confirmDelete(textPost: textPostToDelete)
            
            
        }
    }
    
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

