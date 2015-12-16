//
//  ViewController.swift
//  OnTheMap
//
//  Created by Lupti on 12/14/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate  {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var udacityClient: UdacityClient?
    var applicationDelegate: AppDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        signUpForNotifications()
        udacityClient = UdacityClient.sharedInstance
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
    }
    
    func login(){
        self.loginButton.enabled = false
        activityIndicator.startAnimating()
        if let udacityClient = udacityClient {
            udacityClient.loginWith(emailTextField.text!, password: passwordTextField.text!){
                data, error in
                if data != nil {
                    if let _ = self.applicationDelegate{
                        if self.applicationDelegate != nil {
                            self.applicationDelegate?.currentStudent =
                                Student(dictionary: data!)
                            self.getPublicData()
                        }else{ self.showError("Error", message: "Unable to login") }
                    } else { self.showError("Error", message: "Unable to login") }
                } else {
                    self.showError("Error", message: "Unable to login")
                }
            }
        } else { showError("Error", message: "Unable to login") }
    }
    
    func getPublicData(){
        if let applicationDelegate = applicationDelegate{
            if let key = applicationDelegate.currentStudent?.uniqueKey{
                udacityClient?.getStudentDataWith(key){
                    data, errorString in
                    if let data = data {
                        dispatch_async(dispatch_get_main_queue()){
                            self.applicationDelegate!.currentStudent!.firstName =
                                data["firstName"] as? String
                            self.applicationDelegate!.currentStudent!.lastName =
                                data["lastName"] as? String
                            self.activityIndicator.stopAnimating()
                            self.loginButton.enabled = true
                            //Transition
                            self.transitionToMap()
                        }
                    } else {
                        self.showError("Error", message: errorString!)
                    }
                }
            } else { showError("Error", message: "Unable to access key") }
        } else { showError("Error", message: "Unable to accessing application") }
    }
    
    @IBAction func loginPressed(sender: AnyObject) {
        login()
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
            self.loginButton.enabled = true
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    func transitionToMap() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let tabController = storyboard.instantiateViewControllerWithIdentifier("TabController") as? UITabBarController
        if let tabController = tabController{
            presentViewController(tabController, animated: true, completion: nil)
        } else {
            showError("Error", message: "Unabel To Transition")
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
            login()
        } else {
            passwordTextField.resignFirstResponder()
            emailTextField.resignFirstResponder()
        }
        return false
    }
    
}
