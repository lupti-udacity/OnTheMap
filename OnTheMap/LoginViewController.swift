//
//  ViewController.swift
//  OnTheMap
//
//  Created by Lupti on 12/14/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FBSDKCoreKit
import FBSDKShareKit

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate  {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // Not sure the BorderedButton makes the butten appears better?
    @IBOutlet weak var loginUdacityButton: BorderedButton!

    // Make sure this activityIndicator is on the bottom of the view item list in order to show it on top of the other view items.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    @IBAction func udacitySignup(sender: AnyObject) {
        let app = UIApplication.sharedApplication()
        
        if let url = NSURL(string: "https://www.udacity.com/account/auth#!/signin"){
            if app.canOpenURL(url){
                app.openURL(url)
            }
        }
    }
   
    var udacityClient: UdacityClient?
    var applicationDelegate: AppDelegate?
    var fbLoginManager: FBSDKLoginManager?
    var studentClient: StudentClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /* Configure the UI */
        self.configureUI()

        emailTextField.delegate = self
        passwordTextField.delegate = self
        signUpForNotifications()
        udacityClient = UdacityClient.sharedInstance
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
        
        // Student 
        studentClient = StudentClient.sharedInstance
        
        // FBSDK
        if (FBSDKAccessToken.currentAccessToken() != nil)
        {
            // User is already logged in, do work such as go to next view controller.
            print("FB User has logged in.")
        }
        else
        {
            print("FB User has NOT logged in.")
        }
        
        fbLoginButton.delegate = self
        fbLoginButton.readPermissions = ["public_profile", "email", "user_friends"]
        fbLoginManager?.logOut()
    }
    
    /* Absoultely required FB loginButton function*/
    func loginButton(fbLoginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        guard error == nil else {
            print(error.localizedDescription)
            return
        }
        
        guard result.token != nil else {
            return
        }
       
        // Login to Udacity using FB token recieved here.
        if let udacityClient = udacityClient {
            udacityClient.loginWithFB(FBSDKAccessToken.currentAccessToken().tokenString) {
                data, error in
                    if data != nil {
                        if let _ = self.applicationDelegate{
                            if self.applicationDelegate != nil {
                                self.studentClient?.currentStudent = Student(dictionary: data!)
                                self.getPublicData()
                            }else{ self.showError("Error", message: "System internal error 1") }
                    } else { self.showError("Error", message: "System internal error 2") }
                } else {
                    self.showError("Error", message: "Facebook credential error")
                }
            }
        } else { showError("Error", message: "System internall error 3") }
    }

    /* Another Required FB loginButtonDidLogOut function holder */
    func loginButtonDidLogOut(fbLoginButton: FBSDKLoginButton!) {
        /* This function is required by the FBSDKLogin but not necessary implement here. */
        print("FB loginButtonDidLogOut(fbLoginButton: FBSDKLoginButton!)")
        print("*** User Did Logout!")
    }

    // Udacity login
    func loginUdacity(){
        self.loginUdacityButton.enabled = false
        activityIndicator.startAnimating()
        if let udacityClient = udacityClient {
            udacityClient.loginWith(emailTextField.text!, password: passwordTextField.text!){
                data, error in
                guard error == nil else {
                    self.showError("Error", message: error! + " OR Invalid User ID and Password. Please Try Agin!")
                    return
                }
                if data != nil {
                    if let _ = self.applicationDelegate{
                        if self.applicationDelegate != nil {
                            self.studentClient?.currentStudent =
                                Student(dictionary: data!)
                            self.getPublicData()
                        }else{ self.showError("Error", message: "System internal error 1") }
                    } else { self.showError("Error", message: "System internal error 2.") }
                } else {
                    self.showError("Error", message: "Incorrect Email or Password. Please try again!")
                }
            }
        } else { showError("Error", message: "System internal error 3") }
    }
    
    func getPublicData(){
        dispatch_async(dispatch_get_main_queue()){
        if let _ = self.applicationDelegate{
            if let key = self.studentClient!.currentStudent?.uniqueKey{
                self.udacityClient?.getStudentDataWith(key){
                    data, errorString in
                    if let data = data {
                        print("**** 2nd step getStudentDataWith Unique Key is \(data)")
                        dispatch_async(dispatch_get_main_queue()){
                            self.studentClient!.currentStudent!.firstName =
                                data["firstName"] as? String
                            self.studentClient!.currentStudent!.lastName =
                                data["lastName"] as? String
                            self.activityIndicator.stopAnimating()
                            self.loginUdacityButton.enabled = true
                            //Transition
                            self.transitionToMap()
                        }
                    } else {
                        self.showError("Error", message: errorString!)
                    }
                }
            } else { self.showError("Error", message: "Unable to access key") }
        } else { self.showError("Error", message: "Unable to accessing application") }
        }
    }
   
    // Udacity loginButton did pressed
    @IBAction func loginPressed(sender: AnyObject) {
        loginUdacity()
    }
    
    //MARK: - Helper Methods
    
    func signUpForNotifications() {
        let center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "keyboardDidShow:", name:
            UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func showError(title: String? , message: String?) {
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.stopAnimating()
            self.loginUdacityButton.enabled = true
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    func transitionToMap() {
        dispatch_async(dispatch_get_main_queue()){
            
            let tabController = self.storyboard!.instantiateViewControllerWithIdentifier("TabController") as? UITabBarController
            if let tabController = tabController{
                self.presentViewController(tabController, animated: true, completion: nil)
            } else {
                self.showError("Error", message: "Unabel To Transition")
            }
        }
    }
    
    //MARK: - User Interface
    
    func keyboardDidShow(notification: NSNotification){
        if let info:NSDictionary = notification.userInfo {
            let keyboardSize =
            (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight = keyboardSize.height
            self.view.frame.origin.y = -(keyboardHeight)
        }
    }
    
    func keyboardWillHide(notification: NSNotification){
        self.view.frame.origin.y = 0.0
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if emailTextField.isFirstResponder() && emailTextField.text!.isEmpty == false{
            passwordTextField.becomeFirstResponder()
        } else if passwordTextField.isFirstResponder() && !passwordTextField.text!.isEmpty {
            loginUdacity()
        } else {
            passwordTextField.resignFirstResponder()
            emailTextField.resignFirstResponder()
        }
        return false
    }
    
    //Mark: -Facebook Login stuff
    
    func returnUserData()
    {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "name,email"])
        graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
            }
            else
            {
                print("fetched user: \(result)")
                let userName : NSString = result.valueForKey("name") as! NSString
                print("User Name is: \(userName)")
                let userEmail : NSString = result.valueForKey("email") as! NSString
                print("User Email is: \(userEmail)")
            }
        })
    }

    func configureUI() {
        /* Configure background gradient */
        // Configure login button
        loginUdacityButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        loginUdacityButton.highlightedBackingColor = UIColor(red: 0.3, green: 0.298, blue: 0.686, alpha:1.0)
        loginUdacityButton.backingColor = UIColor.redColor()
        loginUdacityButton.backgroundColor = UIColor.redColor()
        loginUdacityButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    }

    
    
}
