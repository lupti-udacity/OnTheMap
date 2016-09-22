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
        DispatchQueue.main.async{
            self.activityIndicator.startAnimating()
            guard let student = self.currentStudent, let lon = student.longitude, let lat = student.latitude else {
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
            MKMapCamera(lookingAtCenter: coordinate, fromEyeCoordinate: coordinate, eyeAltitude: 10000.0)
            print("*** Camera is \(cammera)")
            /* For zooming in to the location you entered in, use mapView.setCamera to set the zoomed in and 3D effect */
            self.mapView.setCamera(cammera, animated: true)
            self.activityIndicator.stopAnimating()
        }
    }
    
    //MARK: - Target Action
    
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitButtonPressed(_ sender: AnyObject) {
        self.activityIndicator.startAnimating()
        UIView.animate(withDuration: 0.2, animations: {
            self.activityIndicator.color = UIColor.blue
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
                print("*** Error: \(errorString)")
                self.showAlert("Error", message: errorString)
                return
            }
            if self.activityIndicator.isAnimating {
                self.activityIndicator.stopAnimating()
            }
            print("overwriteLocationObject")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
  
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
            if self.activityIndicator.isAnimating {
                print("activityIndicator is running")
                self.activityIndicator.stopAnimating()
            }
            print("activity Indicator is stopped \(self.activityIndicator.isAnimating)")
            self.presentingViewController?.dismiss(animated: true, completion: nil)
            
        }
    }
    
    //MARK: - Helper Methods
    
    func verifyUrl(_ urlString: String?) ->Bool{
        if let urlString = urlString{
            let pattern = "^(https?:\\/\\/)([a-zA-Z0-9_\\-~]+\\.)+[a-zA-Z0-9_\\-~\\/\\.]+$"
            if let _ = urlString.range(of: pattern, options: .regularExpression){
                if let url = URL(string: urlString){
                    if UIApplication.shared.canOpenURL(url){
                        return true
                    } else { return false }
                } else { return false }
            } else { return false }
        } else { return false }
    }
    
    func showAlert(_ title: String? , message: String?) {
        DispatchQueue.main.async{
            self.activityIndicator.stopAnimating()
            if title != nil && message != nil {
                let errorAlert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                errorAlert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
            }
        }
    }
    
    //MARK: - User Interface
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if linkTextField.isFirstResponder {
            linkTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if linkTextField.isFirstResponder && linkTextField.text!.isEmpty == false{
            linkTextField.resignFirstResponder()
        }
        
        return false
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.red
            pinView!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        }
        else { pinView!.annotation = annotation }
        
        return pinView
    }
    
}
