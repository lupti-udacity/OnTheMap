//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit
import MapKit

/*
    Note: On this page we turn the activityIndicator animation ON to allow the activity effect as it is  transitioning from Login page to MapView page.
    However, we can leave the animation OFF if it is intended to be triggered by some button action on this page. The activity animation will need to call its startAnimation() function.

*/

class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mapView: MKMapView!
    
    var uniqueKey: String?
    var applicationDelegate: AppDelegate?
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ASK FOR AUTHORISATION FROM USER, Not recommended: privacy intrusion.
        //self.locationManager.requestAlwaysAuthorization()
        
        //for useq in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled(){
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            
        
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        uniqueKey = applicationDelegate?.currentStudent?.uniqueKey
        activityIndicator.hidesWhenStopped = true
        }
        
        self.mapView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        getStudentsFromServer()
    }
    
    func getStudentsFromServer() {
        
        let parseClient = ParseClient.sharedInstance
        parseClient.getStudentsLocation(){ (students, errorString) in
            self.activityIndicator.startAnimating()
            if let students = students {
                if let applicationDelegate = self.applicationDelegate{
                    var studentArray: [Student] = [Student]()
                    for studentData in students {
                        studentArray.append( Student(dictionary: studentData) )
                    }
                    if studentArray.count > 0 {
                        dispatch_async(dispatch_get_main_queue()){
                            applicationDelegate.students = studentArray
                            // This is a critical step to repopulate or refreash the entire physical mapView's annotations
                            if self.mapView.annotations.count > 0 {
                                self.mapView.removeAnnotations(self.mapView.annotations)
                                self.addAnnotationsToMap()
                            } else {
                                self.addAnnotationsToMap()
                            }
                            self.activityIndicator.stopAnimating()
                        }
                        
                    } else { self.stopActivityIndicator() }
                } else { self.showAlert("Error", message: "Unable to access App Delegate") }
            }else {
                if let errorString = errorString {
                    self.showAlert("Error", message: errorString)
                } else {
                    self.showAlert("Error", message: "Unable to retrieve data")
                }
            }
        }
    }
    
    func addAnnotationsToMap() {
        dispatch_async(dispatch_get_main_queue()){
            if let students = self.applicationDelegate?.students{
                var annotations = [MKAnnotation]()
                for student in students {
                    if let lon = student.longitude,lat = student.latitude, first = student.firstName, last = student.lastName, media = student.mediaURL {
                        let lat = CLLocationDegrees(Double((lat)))
                        let long = CLLocationDegrees(Double((lon)))
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = "\(first) \(last)"
                        annotation.subtitle = media
                        annotations.append(annotation)
                    }
                }
                if annotations.count <= 0 {
                    self.showAlert("Alert", message: "No annotations avaliable")
                } else {
                    self.mapView.addAnnotations(annotations)
                }
            } else {
                self.showAlert("Error", message: "Unable to get student data")
            }
        }
    }
    
    //MARK: - Actions
    
    @IBAction func reloadButtonPressed(sender: AnyObject) {
        getStudentsFromServer()
    }

    @IBAction func addPinPressed(sender: AnyObject) {
    
        let parseClient = ParseClient.sharedInstance
        parseClient.queryForStudent(uniqueKey!){
            student, errorString in
            if let student = student {
                self.applicationDelegate?.onTheMap = true
                self.applicationDelegate?.currentStudent = student
            } else {
                self.applicationDelegate?.onTheMap = false
            }
            if student == nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let addNewPin = storyboard.instantiateViewControllerWithIdentifier("addNewPin") as? UINavigationController
                self.presentViewController(addNewPin!, animated: true, completion: nil)
            } else {
                self.showOverwriteAlert("Alert", message: "Student pin already exists", student: student)
            }
        }
    }

    @IBAction func logoutPressed(sender: AnyObject) {
        let logoutController = presentingViewController as? LoginViewController
        logoutController?.passwordTextField.text = ""
        applicationDelegate?.students = nil
        applicationDelegate?.currentStudent = nil
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil )
        let udacityClient = UdacityClient.sharedInstance
        udacityClient.logoutSession()
    }
    
    //MARK: - Helper Methods
    
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
    
    func showOverwriteAlert(title: String?, message: String?, student: Student?) {
        dispatch_async(dispatch_get_main_queue()){
            if title != nil && message != nil {
                let alert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "cancel", style: UIAlertActionStyle.Default, handler: nil))
                alert.addAction(UIAlertAction(title: "overwrite", style: UIAlertActionStyle.Default, handler: { alert -> Void in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let addNewPin = storyboard.instantiateViewControllerWithIdentifier("addNewPin") as? UINavigationController
                    self.presentViewController(addNewPin!, animated: true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    func stopActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.redColor()
            pinView!.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        }
        else { pinView!.annotation = annotation }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            
            if let url = NSURL(string: annotationView.annotation!.subtitle!!){
                if app.canOpenURL(url){
                    app.openURL(url)
                }
            }
        }
    }
    
}
