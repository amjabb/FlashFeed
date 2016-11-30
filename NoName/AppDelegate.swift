//
//  AppDelegate.swift
//  NoName
//
//  Created by Amir Jabbari on 11/15/16.
//  Copyright © 2016 Amir Jabbari. All rights reserved.
//

import UIKit
import Google
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        // assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().clientID = "686325193777-pfi6gifs6qk8dki3o7j6e9p986dprbpt.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().signInSilently()
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            /* Code to show your tab bar controller */
            print("user is signed in")
            let sb = UIStoryboard(name: "Main", bundle: nil)
            if let tabBarVC = sb.instantiateViewController(withIdentifier: "TabController") as? UITabBarController {
                window!.rootViewController = tabBarVC
            }
        } else {
            print("user is NOT signed in")
            /* code to show your login VC */
            let sb = UIStoryboard(name: "Main", bundle: nil)
            if let tabBarVC = sb.instantiateViewController(withIdentifier: "LoginViewController") as UIViewController? {
                window!.rootViewController = tabBarVC
            }
        }
        // Override point for customization after application launch.
        let settings = UIUserNotificationSettings(types: [.alert,.badge,.sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        return true
    }
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: options[UIApplicationOpenURLOptionsKey.annotation])
    }
    
    private let database = CKContainer.default().publicCloudDatabase
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            var doesUserExist:Bool!
            self.database.fetch(withRecordID: CKRecordID(recordName: user.userID)) { fetchedPlace, error in
                guard fetchedPlace != nil else {
                    print("USER DOESNT EXIST")
                    doesUserExist = false
                    return
                }
                print("USER DOES EXIST")
                doesUserExist = true
                // handle errors here
            }
            sleep(4)
            if !doesUserExist {
                // Perform any operations on signed in user here.
                var ckUser: CKRecord?
                if ckUser == nil {
                    ckUser = CKRecord(recordType: "User", recordID: CKRecordID(recordName: user.userID) )
                }
                ckUser?["userID"] = user.userID as CKRecordValue
                ckUser?["userAuthToken"] = user.authentication.idToken as CKRecordValue
                ckUser?["userName"] = user.profile.name as CKRecordValue
                ckUser?["userEmail"] = user.profile.email as CKRecordValue
                if user.profile.hasImage {
                    ckUser?["profilePicture"] = String(describing: user.profile.imageURL(withDimension: 100)!) as CKRecordValue?
                }
                iCloudSaveRecord(recordToSave: ckUser!)
            }
            _ = user.userID                  // For client-side use only!
            _ = user.authentication.idToken // Safe to send to the server
            _ = user.profile.name
            _ = user.profile.email
            //print("Welcome: ,\(userId), \(idToken), \(fullName), \(email)")
            let sb = UIStoryboard(name: "Main", bundle: nil)
            if let tabBarVC = sb.instantiateViewController(withIdentifier: "TabController") as? UITabBarController {
                window!.rootViewController = tabBarVC
            }
        } else {
            print("\(error.localizedDescription)")
        }
    }
    
    func iCloudSaveRecord(recordToSave: CKRecord){
        database.save(recordToSave, completionHandler: { (savedRecord, error) in
            if error?._code == CKError.serverRecordChanged.rawValue {
                // optimistic locking failed, ignore
            } else if error != nil {
                print(error!)
                //nothing
            }
        })
        print("Record saved to icloud")
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        //
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

