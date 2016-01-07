//
//  TableListController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

/*
Note: On this page we turn the activityIndicator animation ON to allow the activity effect as it is transitioing from Login page to Table View page.
However, we can leave the animation OFF if it is intended to be triggered by some button action on this page. The activity animation will then need to call its startAnimation() function.

*/


import UIKit

class TableListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var applicationDelegate: AppDelegate?
    var students: [Student]?
    var uniqueKey: String?
    var parseClient: ParseClient?
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBAction func logoutPressed(sender: AnyObject) {
        //activityIndicator.startAnimating()
        let logoutController = presentingViewController as? LoginViewController
        logoutController?.passwordTextField.text = ""
        parseClient?.students = nil
        parseClient?.currentStudent = nil
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil )
        let udacityClient = UdacityClient.sharedInstance
        udacityClient.logoutSession()
    }

    @IBAction func refresh(sender: AnyObject) {
        print("Refresh from the server")
        getStudentsFromServer()
    }
    
    @IBAction func addPinPressed(sender: AnyObject) {
        print("addPinPressed")
    
        //let parseClient = ParseClient.sharedInstance
        self.parseClient!.queryForStudent(uniqueKey!){
            student, errorString in
            if let student = student {
                self.applicationDelegate?.onTheMap = true
                self.parseClient?.currentStudent = student
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

    //MARK: - Helper Methods
    
    func showOverwriteAlert(title: String?, message: String?, student: Student?) {
        dispatch_async(dispatch_get_main_queue()){
            self.activityIndicator.stopAnimating()
            if title != nil && message != nil {
                let alert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "cancel", style: UIAlertActionStyle.Default, handler: nil))
                alert.addAction(UIAlertAction(title: "overwrite", style: UIAlertActionStyle.Default, handler: { alert -> Void in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let addPinNav = storyboard.instantiateViewControllerWithIdentifier("addNewPin") as? UINavigationController
                    self.presentViewController(addPinNav!, animated: true, completion: nil)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
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
    
    func getStudentsFromServer() {
        
        let parseClient = ParseClient.sharedInstance
        self.activityIndicator.startAnimating()
        UIView.animateWithDuration(0.4, animations: {
            self.activityIndicator.color = UIColor.blueColor()
            self.activityIndicator.alpha = 1.0
        })
        
        parseClient.getStudentsLocation(){ (students, errorString) in
            
            if let students = students {
                if let _ = self.applicationDelegate{
                    var studentArray: [Student] = [Student]()
                    for studentData in students {
                        
                        studentArray.append( Student(dictionary: studentData) )
                    }
                    if studentArray.count > 0 {
                        dispatch_async(dispatch_get_main_queue()){
                            
                            parseClient.students = studentArray
                            // assign students to the local students variable for the local table view scope
                            self.students = studentArray
                            self.tableView.reloadData()
                            self.activityIndicator.stopAnimating()
                        }
                    }
                } else {
                    self.showAlert("Error", message: "Unable to access App Delegate")
                    
                }
            } else {
                if let errorString = errorString {
                    self.showAlert("Error", message: errorString)
                    
                } else {
                    self.showAlert("Error", message: "Unable to retrieve data")
                    
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        parseClient = ParseClient.sharedInstance
        getStudentsFromServer()
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        students = parseClient?.students
        uniqueKey = parseClient?.currentStudent?.uniqueKey
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewDidAppear(animated: Bool) {
        getStudentsFromServer()
        activityIndicator.hidesWhenStopped = true
        
    }
  
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        getStudentsFromServer()
        
        if let _ = parseClient?.students {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
    }

    //MARK: - TableView Data Sourse Methods
    // A table delegate, cellForRawAtIndexPath automatically populates the table row by row, an important delegate methid for the table.
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            if let students = self.parseClient?.students
            {
                
                let student = students[indexPath.row]
                
                if let firstName = student.firstName, lastName = student.lastName {
                    cell.textLabel?.text = "\(firstName) \(lastName)"
                }
                if let url = student.mediaURL {
                    cell.detailTextLabel?.text = "\(url)"
                }
            }
            return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let rows = self.parseClient?.students?.count{
            return rows
        } else {
            return 0
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        getStudentsFromServer()
        
        if let urlString = students![indexPath.row].mediaURL
        {
            let app = UIApplication.sharedApplication()
            if let url = NSURL(string: urlString){
                if app.canOpenURL(url){
                    app.openURL(url)
                }
            }
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if let students = students{
            if let mapString = students[indexPath.row].mapString, cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.detailTextLabel?.text = mapString
            }
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if let students = students {
            if let urlString = students[indexPath.row].mediaURL{
                let app = UIApplication.sharedApplication()
                if let url = NSURL(string: urlString){
                    if app.canOpenURL(url){
                        app.openURL(url)
                    }
                }
            }
        }
    }
    
}
