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
    var studentClient: StudentClient?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ASK FOR AUTHORISATION FROM USER, Not recommended: privacy intrusion.
        //self.locationManager.requestAlwaysAuthorization()
        
        //for useq in foreground
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled(){
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            studentClient = StudentClient.sharedInstance
        
            applicationDelegate = UIApplication.shared.delegate as? AppDelegate
            uniqueKey = studentClient!.currentStudent?.uniqueKey
            activityIndicator.hidesWhenStopped = true
        }
        
        self.mapView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getStudentsFromServer()
    }
    
    func getStudentsFromServer() {
        self.activityIndicator.startAnimating()
        UIView.animate(withDuration: 0.3, animations: {
            self.activityIndicator.color = UIColor.red
            self.activityIndicator.alpha = 1.0
        })

        let parseClient = ParseClient.sharedInstance
        parseClient.getStudentsLocation(){ (students, errorString) in
            
            if let students = students {
                if let _ = self.studentClient{
                    self.studentClient!.studentArray = [Student]()
                    for studentData in students {
                        self.studentClient!.studentArray?.append(Student(dictionary: studentData as NSDictionary))
                    }
                    if self.studentClient!.studentArray!.count > 0 {
                      DispatchQueue.main.async{
                            self.studentClient!.students = self.studentClient!.studentArray
                            // This is a critical step to repopulate or refreash the entire physical mapView's annotations
                            if self.mapView.annotations.count > 0 {
                                self.mapView.removeAnnotations(self.mapView.annotations)
                                self.addAnnotationsToMap()
                            } else {
                                self.addAnnotationsToMap()
                            }
                            self.activityIndicator.stopAnimating()
                        }
                        
                    } else { self.activityIndicator.stopAnimating() }
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
        DispatchQueue.main.async{
            if let students = self.studentClient?.students{
                var annotations = [MKAnnotation]()
                for student in students {
                    if let lon = student.longitude,let lat = student.latitude, let first = student.firstName, let last = student.lastName, let media = student.mediaURL {
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
    
    @IBAction func reloadButtonPressed(_ sender: AnyObject) {
        getStudentsFromServer()
    }

    @IBAction func addPinPressed(_ sender: AnyObject) {
        if self.activityIndicator.isAnimating {
            self.activityIndicator.stopAnimating()
        }
        let parseClient = ParseClient.sharedInstance
        parseClient.queryForStudent(uniqueKey!){
            student, errorString in
            if let student = student {
                self.studentClient?.onTheMap = true
                self.studentClient?.currentStudent = student
            } else {
                self.studentClient?.onTheMap = false
            }
            if student == nil {
                
                let addNewPin = self.storyboard!.instantiateViewController(withIdentifier: "addNewPin") as? UINavigationController
                self.present(addNewPin!, animated: true, completion: nil)
            } else {
                self.showOverwriteAlert("Alert", message: "Student pin already exists", student: student)
            }
        }
    }

    @IBAction func logoutPressed(_ sender: AnyObject) {
        let logoutController = presentingViewController as? LoginViewController
        logoutController?.passwordTextField.text = ""
        studentClient?.students = nil
        studentClient?.currentStudent = nil
        self.presentingViewController?.dismiss(animated: true, completion: nil )
        let udacityClient = UdacityClient.sharedInstance
        udacityClient.logoutSession()
    }
    
    //MARK: - Helper Methods
    
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
    
    func showOverwriteAlert(_ title: String?, message: String?, student: Student?) {
        DispatchQueue.main.async{
            if title != nil && message != nil {
                let alert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "cancel", style: UIAlertActionStyle.default, handler: nil))
                alert.addAction(UIAlertAction(title: "overwrite", style: UIAlertActionStyle.default, handler: { alert -> Void in
                    
                    let addNewPin = self.storyboard!.instantiateViewController(withIdentifier: "addNewPin") as? UINavigationController
                    self.present(addNewPin!, animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else { pinView!.annotation = annotation }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.shared
            
            if let url = URL(string: annotationView.annotation!.subtitle!!){
                if app.canOpenURL(url){
                    app.openURL(url)
                }
            }
        }
    }
    
}
