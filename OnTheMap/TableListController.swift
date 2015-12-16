//
//  TableController.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit

class TableController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var applicationDelegate: AppDelegate?
    var students: [Student]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applicationDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        students = applicationDelegate?.students
    }
    
    override func viewDidAppear(animated: Bool) {
        students = applicationDelegate?.students
    }
    
    //MARK: - TableView Data Sourse Methods
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
            return rows
        } else {
            return 0
        }
    }
    
    //MARK: - TableView Delegate Methods
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let urlString = students![indexPath.row].mediaURL, cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.detailTextLabel?.text = urlString
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
