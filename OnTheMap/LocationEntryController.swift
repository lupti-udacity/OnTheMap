//
//  LocationEntryController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit
import MapKit

class LocationEntryController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var locationTextField: UITextField!
    var applicationDelegate: AppDelegate?
    var studentClient: StudentClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationTextField.delegate = self
        signUpForNotifications()
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
        studentClient = StudentClient.sharedInstance
    }
    
    @IBAction func didPressCancel(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressEnter(sender: AnyObject) {
        guard locationTextField.text?.isEmpty == false else {
            showAlert("ERROR", message: "Enter a location")
            return
        }
        
        dispatch_async(dispatch_get_main_queue()){
        self.activityIndicator.startAnimating()

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.locationTextField.text!){
            placemark, error in

            if let error = error {
                self.showAlert("ERROR", message: error.localizedDescription)
                return
            }

            guard let _ = self.applicationDelegate, placemark = placemark else {
                self.showAlert("ERROR", message: "Unable to find location")
                return
            }
            guard placemark.count > 0 else {
                self.showAlert("ERROR", message:"Unable to find location")
                return
            }
            let placemark1 = placemark.first!
            guard let country = placemark1.country, state = placemark1.administrativeArea else {
                self.showAlert("ERROR", message:"Be more specific in location")
                return
            }
            

            guard let city = placemark1.locality else {
                self.studentClient!.currentStudent?.mapString = "\(state), \(country)"
                self.studentClient!.currentStudent?.latitude = (placemark1.location!.coordinate.latitude)
                self.studentClient!.currentStudent?.longitude = (placemark1.location!.coordinate.longitude)
                self.presentViewWith(self.studentClient!.currentStudent?.mapString,lat: nil,lon: nil)
                return
                
            }
            self.studentClient!.currentStudent?.mapString = "\(city), \(state), \(country)"
            self.studentClient!.currentStudent?.latitude = (placemark1.location!.coordinate.latitude)
            self.studentClient!.currentStudent?.longitude = (placemark1.location!.coordinate.longitude)
            self.presentViewWith(self.studentClient!.currentStudent?.mapString,lat: self.studentClient!.currentStudent?.latitude,lon: self.studentClient!.currentStudent?.longitude)
            }
            if self.activityIndicator.isAnimating() {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    //MARK: - Helper Methods
    
    func signUpForNotifications() {
        let center: NSNotificationCenter = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "keyboardDidShow:", name:
            UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    //Shows alert and stops activity indicator
    func showAlert(title: String? , message: String?) {
        dispatch_async(dispatch_get_main_queue()){
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    //Presents viewController if value is not nil; on main thread
    
    func presentViewWith(mapString: String?, lat: Double?, lon: Double? ) {
        dispatch_async(dispatch_get_main_queue()){
            if mapString != nil {
                self.performSegueWithIdentifier("showLinkController", sender: self)
            } else {
                self.showAlert("ERROR", message: "Unable to find location: please try again")
            }
        }
    }
    
    //MARK: - User Interface 
    // Must have else crash.

    func keyboardDidShow(notification: NSNotification){
        if view.frame.origin.y == 0 {
            view.frame.origin.y =
                -(locationTextField.frame.origin.y - topLayoutGuide.length  )
        }
    }
    
    func keyboardWillHide(notification: NSNotification){
        //Move view back in position
        self.view.frame.origin.y = 0.0
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if locationTextField.isFirstResponder() {
            locationTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if locationTextField.isFirstResponder() && locationTextField.text!.isEmpty == false{
            locationTextField.resignFirstResponder()
        }
        return false
    }

}