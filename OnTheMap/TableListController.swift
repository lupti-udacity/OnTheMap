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
    var uniqueKey: String?
    var parseClient: ParseClient?
    var studentClient: StudentClient?
    
   
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    @IBAction func logoutPressed(_ sender: AnyObject) {
        let logoutController = presentingViewController as? LoginViewController
        logoutController?.passwordTextField.text = ""
        studentClient?.students = nil
        studentClient?.currentStudent = nil
        self.presentingViewController?.dismiss(animated: true, completion: nil )
        let udacityClient = UdacityClient.sharedInstance
        udacityClient.logoutSession()
    }

    @IBAction func refresh(_ sender: AnyObject) {
        getStudentsFromServer()
    }
    
    @IBAction func addPinPressed(_ sender: AnyObject) {
        self.parseClient!.queryForStudent(uniqueKey!){
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

    override func viewDidLoad() {
        super.viewDidLoad()
        parseClient = ParseClient.sharedInstance
        studentClient = StudentClient.sharedInstance
        getStudentsFromServer()
        applicationDelegate = UIApplication.shared.delegate as? AppDelegate
        uniqueKey = studentClient?.currentStudent?.uniqueKey
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getStudentsFromServer()
        activityIndicator.hidesWhenStopped = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        getStudentsFromServer()
        
        if let _ = studentClient?.students {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    
    //MARK: - Helper Methods
    
    func showOverwriteAlert(_ title: String?, message: String?, student: Student?) {
        DispatchQueue.main.async{
            self.activityIndicator.stopAnimating()
            if title != nil && message != nil {
                let alert =
                UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "cancel", style: UIAlertActionStyle.default, handler: nil))
                alert.addAction(UIAlertAction(title: "overwrite", style: UIAlertActionStyle.default, handler: { alert -> Void in
                    
                    let addPinNav = self.storyboard!.instantiateViewController(withIdentifier: "addNewPin") as? UINavigationController
                    self.present(addPinNav!, animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
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
    
    func getStudentsFromServer() {
        
        let parseClient = ParseClient.sharedInstance
        self.activityIndicator.startAnimating()
        UIView.animate(withDuration: 0.4, animations: {
            self.activityIndicator.color = UIColor.blue
            self.activityIndicator.alpha = 1.0
        })
        
        parseClient.getStudentsLocation(){ (students, errorString) in
            
            if let students = students {
                if let _ = self.applicationDelegate{
                    self.studentClient!.studentArray = [Student]()
    
                    for studentData in students {
                        
                      self.studentClient!.studentArray?.append( Student(dictionary: studentData as NSDictionary) )
                    }
                    if self.studentClient!.studentArray!.count > 0 {
                        DispatchQueue.main.async{
                            
                            self.studentClient!.students = self.studentClient!.studentArray
                            // assign students to the local students variable for the local table view scope
                            //self.students = parseClient.studentArray
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


    //MARK: - TableView Data Sourse Methods
    // A table delegate, cellForRawAtIndexPath automatically populates the table row by row, an important delegate methid for the table.
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            if let students = self.studentClient?.students
            {
                
                let student = students[(indexPath as NSIndexPath).row]
                
                if let firstName = student.firstName, let lastName = student.lastName {
                    cell.textLabel?.text = "\(firstName) \(lastName)"
                }
                if let url = student.mediaURL {
                    cell.detailTextLabel?.text = "\(url)"
                }
            }
            return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let rows = self.studentClient?.students?.count{
            return rows
        } else {
            return 0
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        getStudentsFromServer()
        
        if let urlString = studentClient!.students![(indexPath as NSIndexPath).row].mediaURL
        {
            let app = UIApplication.shared
            if let url = URL(string: urlString){
                guard app.canOpenURL(url) else {
                    showAlert("Error", message: "Invalid URI resource scheme.")
                    return
                }
                guard app.openURL(url) else {
                        showAlert("URL: \(url)", message: "Inaccessible URI")
                        return
                    }
            }
        } else {
            showAlert("Error", message: "Inaccessible student record")
            return
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let students = studentClient!.students{
            if let mapString = students[(indexPath as NSIndexPath).row].mapString, let cell = tableView.cellForRow(at: indexPath) {
                cell.detailTextLabel?.text = mapString
            }
        }
    }
    
    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        if let students = studentClient!.students {
            if let urlString = students[(indexPath as NSIndexPath).row].mediaURL{
                let app = UIApplication.shared
                if let url = URL(string: urlString){
                    if app.canOpenURL(url){
                        app.openURL(url)
                    }
                }
            }
        }
    }
    
}
