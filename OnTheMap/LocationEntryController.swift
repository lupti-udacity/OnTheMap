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
    var parseClient: ParseClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationTextField.delegate = self
        signUpForNotifications()
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
        parseClient = ParseClient.sharedInstance
    }
    
    @IBAction func didPressCancel(sender: AnyObject) {
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func didPressEnter(sender: AnyObject) {
        if locationTextField.text!.isEmpty{
            showAlert("ERROR", message: "Enter a location")
            return
        }
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationTextField.text!){
            placemark, error in
            if let error = error {
                self.showAlert("ERROR", message: error.localizedDescription)
                return
            }
            //self.activityIndicator.startAnimating()
            if let _ = self.applicationDelegate, placemark = placemark{
                if placemark.count > 0 {
                    let placemark = placemark.first!
                    if let country = placemark.country, state = placemark.administrativeArea{
                        if let city = placemark.locality{
                            self.parseClient!.currentStudent?.mapString = "\(city), \(state), \(country)"
                            self.parseClient!.currentStudent?.latitude = (placemark.location!.coordinate.latitude)
                            self.parseClient!.currentStudent?.longitude = (placemark.location!.coordinate.longitude)
                            self.presentViewWith(self.parseClient!.currentStudent?.mapString,lat: self.parseClient!.currentStudent?.latitude,lon: self.parseClient!.currentStudent?.longitude)
                            //self.stopActivityIndicator()
                        }else {
                            self.parseClient!.currentStudent?.mapString = "\(state), \(country)"
                            self.parseClient!.currentStudent?.latitude = (placemark.location!.coordinate.latitude)
                            self.parseClient!.currentStudent?.longitude = (placemark.location!.coordinate.longitude)
                            self.presentViewWith(self.parseClient!.currentStudent?.mapString,lat: nil,lon: nil)
                            //self.stopActivityIndicator()
                        }
                    } else {
                        self.showAlert("ERROR", message:"Be more specific in location")
                    }
                } else {
                    self.showAlert("ERROR", message:"Unable to find location")
                }
            } else {
                self.showAlert("ERROR", message: "Unable to find location")
            }
        }
    }
    
    //MARK: - Helper Methods
    
    func stopActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.stopAnimating()
        }
    }
    
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