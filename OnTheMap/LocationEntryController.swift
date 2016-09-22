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
        applicationDelegate = UIApplication.shared.delegate as? AppDelegate
        activityIndicator.hidesWhenStopped = true
        studentClient = StudentClient.sharedInstance
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("$$$$$ View Will Appear..."  )
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
    }
    
    @IBAction func didPressCancel(_ sender: AnyObject) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressEnter(_ sender: AnyObject) {
        guard locationTextField.text?.isEmpty == false else {
            showAlert("ERROR", message: "Enter a location")
            return
        }
        
        activityIndicator.startAnimating()
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(self.locationTextField.text!){
            placemark, error in

            if let error = error {
                self.showAlert("ERROR", message: error.localizedDescription)
                return
            }

            guard let _ = self.applicationDelegate, let placemark = placemark else {
                self.showAlert("ERROR", message: "Unable to find location")
                return
            }
            guard placemark.count > 0 else {
                self.showAlert("ERROR", message:"Unable to find location")
                return
            }
            let placemark1 = placemark.first!
            guard let country = placemark1.country, let state = placemark1.administrativeArea else {
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
    }
    
    //MARK: - Helper Methods
    
    func signUpForNotifications() {
        let center: NotificationCenter = NotificationCenter.default
        center.addObserver(self, selector: #selector(LocationEntryController.keyboardDidShow(_:)), name:
            NSNotification.Name.UIKeyboardWillShow, object: nil)
        center.addObserver(self, selector: #selector(LocationEntryController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    //Shows alert and stops activity indicator
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
    
    //Presents viewController if value is not nil; on main thread
    
    func presentViewWith(_ mapString: String?, lat: Double?, lon: Double? ) {
        DispatchQueue.main.async{
            if mapString != nil {
                self.performSegue(withIdentifier: "showLinkController", sender: self)
            } else {
                self.showAlert("ERROR", message: "Unable to find location: please try again")
            }
        }
    }
    
    //MARK: - User Interface 
    // Must have else crash.

    func keyboardDidShow(_ notification: Notification){
        if view.frame.origin.y == 0 {
            view.frame.origin.y =
                -(locationTextField.frame.origin.y - topLayoutGuide.length  )
        }
    }
    
    func keyboardWillHide(_ notification: Notification){
        //Move view back in position
        self.view.frame.origin.y = 0.0
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if locationTextField.isFirstResponder {
            locationTextField.resignFirstResponder()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if locationTextField.isFirstResponder && locationTextField.text!.isEmpty == false{
            locationTextField.resignFirstResponder()
        }
        return false
    }

}
