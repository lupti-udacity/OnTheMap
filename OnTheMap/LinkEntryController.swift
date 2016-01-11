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
    var currentStudent: Student?
    var studentClient: StudentClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        studentClient = StudentClient.sharedInstance
        linkTextField.delegate = self
        currentStudent = studentClient?.currentStudent
        activityIndicator.hidesWhenStopped = true
        addAnnotationsToMap()
    }
    
    func addAnnotationsToMap() {
        dispatch_async(dispatch_get_main_queue()){
            
            guard let student = self.currentStudent, lon = student.longitude, lat = student.latitude else {
                self.showAlert("Error", message: "Unable to get student data")
                return
            }
            let lad = CLLocationDegrees(Double((lat)))
            let long = CLLocationDegrees(Double((lon)))
            let coordinate = CLLocationCoordinate2D(latitude: lad, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            let cammera =
            MKMapCamera(lookingAtCenterCoordinate: coordinate, fromEyeCoordinate: coordinate, eyeAltitude: 10000.0)
            self.mapView.setCamera(cammera, animated: true)

        }
    }
    
    //MARK: - Target Action
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(sender: AnyObject) {
        self.activityIndicator.startAnimating()
        UIView.animateWithDuration(0.2, animations: {
            self.activityIndicator.color = UIColor.blueColor()
            self.activityIndicator.alpha = 1.0
        })
        
        guard let urlString = self.linkTextField.text else{
            showAlert("Error", message:"TextField is empty")
            return
        }
        guard self.verifyUrl(urlString) else {
            self.showAlert("Error", message:"Invalid link")
            return
        }
        self.studentClient?.currentStudent?.mediaURL = "\(urlString)"
        guard let overwrite = studentClient!.onTheMap else {
            self.showAlert("Error", message:"Internal error 2")
            return
        }
        guard overwrite == true else {
            self.addLocationObject()
            return
        }
        self.overwriteLocationObject()
        return
        
    }
    
    func overwriteLocationObject(){
        let parseClient = ParseClient.sharedInstance
        parseClient.overwriteStudent(self.studentClient?.currentStudent){
            (completed, errorString) in
            
            guard completed == true else {
                self.showAlert("Error", message: errorString)
                return
            }
            if self.activityIndicator.isAnimating() {
                self.activityIndicator.stopAnimating()
            }
            print("overwriteLocationObject")
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
  
        }
    }
    
    func addLocationObject(){
        let parseClient = ParseClient.sharedInstance
        parseClient.postStudent(self.studentClient?.currentStudent){
            (completed, errorString) in
            guard completed == true else {
                self.showAlert("Error", message: errorString)
                return
            }
            if self.activityIndicator.isAnimating() {
                print("activityIndicator is running")
                self.activityIndicator.stopAnimating()
            }
            print("activity Indicator is stopped \(self.activityIndicator.isAnimating())")
            self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            
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