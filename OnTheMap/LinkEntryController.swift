//
//  LinkEntryController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit
import MapKit

class LinkEntryController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var linkTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var applicationDelegate: AppDelegate?
    var currentStudent:Student?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        linkTextField.delegate = self
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        currentStudent = applicationDelegate?.currentStudent
        activityIndicator.hidesWhenStopped = true
        addAnnotationsToMap()
    }
    
    func addAnnotationsToMap() {
        dispatch_async(dispatch_get_main_queue()){
            if let student = self.currentStudent, lon = student.longitude, lat = student.latitude{
                let lat = CLLocationDegrees(Double((lat)))
                let long = CLLocationDegrees(Double((lon)))
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
                let cammera =
                MKMapCamera(lookingAtCenterCoordinate: coordinate, fromEyeCoordinate: coordinate, eyeAltitude: 10000.0)
                self.mapView.setCamera(cammera, animated: true)
            } else {
                self.showAlert("Error", message: "Unable to get student data")
            }
        }
    }
    
    //MARK: - Target Action
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(sender: AnyObject) {
        self.activityIndicator.startAnimating()
        if let urlString = linkTextField.text{
            if verifyUrl(urlString){
                applicationDelegate?.currentStudent?.mediaURL = "\(urlString)"
                if let appDelegate = applicationDelegate{
                    if let overwrite = appDelegate.onTheMap{
                        if overwrite {
                            //OVERWRITE
                            self.overwriteLocationObject()
                        } else if overwrite == false{
                            //ADD NEW LOCATION OBJECT
                            self.addLocationObject()
                        }
                    }
                }
            } else { self.showAlert("Error", message:"Invalid link") }
        } else { self.showAlert("Error", message:"TextField is empty") }
    }
    
    func overwriteLocationObject(){
        let parseClient = ParseClient.sharedInstance
        parseClient.overwriteStudent(applicationDelegate?.currentStudent){
            (completed, errorString) in
            if completed == true {
                self.activityIndicator.stopAnimating()
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            } else {
                if let errorString = errorString {
                    self.showAlert("Error", message: errorString)
                }else {
                    self.showAlert("Error", message:"Unable to sumbit student data")
                }
            }
        }
    }
    
    func addLocationObject(){
        let parseClient = ParseClient.sharedInstance
        parseClient.postStudent(applicationDelegate?.currentStudent){
            (completed, errorString) in
            if completed == true {
                self.activityIndicator.stopAnimating()
                self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            } else {
                if let errorString = errorString {
                    self.showAlert("Error", message: errorString)
                }else {
                    self.showAlert("Error", message:"Unable to sumbit student data")
                }
            }
        }
    }
    
    //MARK: - Helper Methods
    
    func verifyUrl(urlString: String?) ->Bool{
        if let urlString = urlString{
            let pattern = "^(https?:\\/\\/)([a-zA-Z0-9_\\-~]+\\.)+[a-zA-Z0-9_\\-~\\/\\.]+$"
            if let _ = urlString.rangeOfString(pattern, options: .RegularExpressionSearch){
                if let url = NSURL(string: urlString){
                    if UIApplication.sharedApplication().canOpenURL(url){
                        return true
                    } else { return false }
                } else { return false }
            } else { return false }
        } else { return false }
    }
    
    func showAlert(title: String? , message: String?) {
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.stopAnimating()
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - User Interface
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if linkTextField.isFirstResponder() {
            linkTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if linkTextField.isFirstResponder() && linkTextField.text!.isEmpty == false{
            linkTextField.resignFirstResponder()
        }
        
        return false
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.DetailDisclosure)
        }
        else { pinView!.annotation = annotation }
        
        return pinView
    }
    
}