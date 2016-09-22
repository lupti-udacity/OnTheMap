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
    
    @IBAction func udacitySignup(_ sender: AnyObject) {
        let app = UIApplication.shared
        
        if let url = URL(string: "https://www.udacity.com/account/auth#!/signin"){
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
        applicationDelegate = UIApplication.shared.delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
        
        // Student 
        studentClient = StudentClient.sharedInstance
        
        // FBSDK
        if (FBSDKAccessToken.current() != nil)
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
    
    /* Absoultely required FB 
    function*/
    func loginButton(_ fbLoginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        guard error == nil else {
            print(error.localizedDescription)
            return
        }
        
        guard result.token != nil else {
            return
        }
       
        // Login to Udacity using FB token recieved here.
        if let udacityClient = udacityClient {
            udacityClient.loginWithFB(FBSDKAccessToken.current().tokenString) {
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
    func loginButtonDidLogOut(_ fbLoginButton: FBSDKLoginButton!) {
        /* This function is required by the FBSDKLogin but not necessary implement here. */
        print("FB loginButtonDidLogOut(fbLoginButton: FBSDKLoginButton!)")
        print("*** User Did Logout!")
    }

    // Udacity login
    func loginUdacity(){
        self.loginUdacityButton.isEnabled = false
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
        DispatchQueue.main.async{
        if let _ = self.applicationDelegate{
            if let key = self.studentClient!.currentStudent?.uniqueKey{
                self.udacityClient?.getStudentDataWith(key){
                    data, errorString in
                    if let data = data {
                        print("**** 2nd step getStudentDataWith Unique Key is \(data)")
                        DispatchQueue.main.async{
                            self.studentClient!.currentStudent!.firstName =
                                data["firstName"] as? String
                            self.studentClient!.currentStudent!.lastName =
                                data["lastName"] as? String
                            self.activityIndicator.stopAnimating()
                            self.loginUdacityButton.isEnabled = true
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
    @IBAction func loginPressed(_ sender: AnyObject) {
        loginUdacity()
    }
    
    //MARK: - Helper Methods
    
    func signUpForNotifications() {
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(LoginViewController.keyboardDidShow(_:)), name:
            NSNotification.Name.UIKeyboardWillShow, object: nil)
        center.addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func showError(_ title: String? , message: String?) {
        DispatchQueue.main.async{
            self.activityIndicator.stopAnimating()
            self.loginUdacityButton.isEnabled = true
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    func transitionToMap() {
        DispatchQueue.main.async{
            
            let tabController = self.storyboard!.instantiateViewController(withIdentifier: "TabController") as? UITabBarController
            if let tabController = tabController{
                self.present(tabController, animated: true, completion: nil)
            } else {
                self.showError("Error", message: "Unabel To Transition")
            }
        }
    }
    
    //MARK: - User Interface
    
    func keyboardDidShow(_ notification: Notification){
        if let info:NSDictionary = (notification as NSNotification).userInfo as NSDictionary? {
            let keyboardSize =
            (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let keyboardHeight = keyboardSize.height
            self.view.frame.origin.y = -(keyboardHeight)
        }
    }
    
    func keyboardWillHide(_ notification: Notification){
        self.view.frame.origin.y = 0.0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if emailTextField.isFirstResponder && emailTextField.text!.isEmpty == false{
            passwordTextField.becomeFirstResponder()
        } else if passwordTextField.isFirstResponder && !passwordTextField.text!.isEmpty {
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
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
            }
            else
            {
                print("fetched user: \(result)")
                let userName : NSString = result.value(forKey: "name") as! NSString
                print("User Name is: \(userName)")
                let userEmail : NSString = result.value(forKey: "email") as! NSString
                print("User Email is: \(userEmail)")
            }
        })
    }

    func configureUI() {
        /* Configure background gradient */
        // Configure login button
        loginUdacityButton.titleLabel?.font = UIFont(name: "AvenirNext-Medium", size: 17.0)
        loginUdacityButton.highlightedBackingColor = UIColor(red: 0.3, green: 0.298, blue: 0.686, alpha:1.0)
        loginUdacityButton.backingColor = UIColor.red
        loginUdacityButton.backgroundColor = UIColor.red
        loginUdacityButton.setTitleColor(UIColor.white, for: UIControlState())
    }

    
    
}
