//
//  TableListController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit

class TableListController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var applicationDelegate: AppDelegate?
    var students: [Student]?
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBAction func logoutPressed(sender: AnyObject) {
        let logoutController = presentingViewController as? LoginViewController
        logoutController?.passwordTextField.text = ""
        applicationDelegate?.students = nil
        applicationDelegate?.currentStudent = nil
        self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil )
    }

    @IBAction func refresh(sender: AnyObject) {
        print("Refresh from the server")
        activityIndicator.startAnimating()
        let parseClient = ParseClient.sharedInstance
        parseClient.getStudentsLocation() {(students, errorString) in
            if let students = students {
                if let applicationDelegate = self.applicationDelegate {
                    var studentArray: [Student] = [Student]()
                    for studentData in students {
                        studentArray.append( Student(dictionary: studentData))
                    }
                    if studentArray.count > 0 {
                        //dispatch_async(dispatch_get_main_queue()) {
                        applicationDelegate.students = studentArray
                        self.tableView.reloadData()
                        //}
                    } else {
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    self.showAlert("Error", message: "Unable to access AppDelegate!")
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
    
    @IBAction func addPinPressed(sender: AnyObject) {
        print("addPinPressed")
       /*
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
        } */
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
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        students = applicationDelegate?.students
        if let rows = students?.count{
            print("Row count is \(rows) in viewDidLoad")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        print("viewDidAppear")
        students = applicationDelegate?.students
        if let rows = students?.count{
            print("Row count is \(rows) in viewDidAppear")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear ")
        if let _ = applicationDelegate?.students {
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
        }
        
    }

    //MARK: - TableView Data Sourse Methods
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            print("cellForRowAtIndexPath in Table")
            let cell =
            tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            if let students = self.students{
                let student = students[indexPath.row]
                if let firstName = student.firstName, lastName = student.lastName{
                    cell.textLabel?.text = "\(firstName) \(lastName)"
                }
                if let location = student.mapString{
                    cell.detailTextLabel?.text = location
                }
            }
            return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let rows = students?.count{
            print("Row count is \(rows)")
            return rows
        } else {
            return 0
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("didSelectRowAtIndexPath in Table")
        if let urlString = students![indexPath.row].mediaURL, cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.detailTextLabel?.text = urlString
        }
    }

    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("didDeselectRowAtIndexPath from table view")
        if let students = students{
            if let mapString = students[indexPath.row].mapString, cell = tableView.cellForRowAtIndexPath(indexPath) {
                cell.detailTextLabel?.text = mapString
            }
        }
    }
    
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        print("accessoryButtonTappedForRowWithIndexPath from table view")
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
