//
//  ParseClient.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit

class ParseClient: NSObject {
    // deprecate Parse DB on August 3, 2016
    //static let studentLocationUrl = "https://api.parse.com/1/classes/StudentLocation/"
    static let studentLocationUrl = "https://parse.udacity.com/parse/classes/StudentLocation"
    static let apiKey = "QuWThTdiRmTux3YaDseUSEpUKo7aBYM737yKd4gY"
    static let aplicationID = "QrX47CA9cyuGewLdsL7o5Eb8iug6Em8ye0dnAbIr"
    static let sharedInstance = ParseClient()
    typealias ParseCompletionHandler =
        (data: [[String: AnyObject]]?, errorString: String?) -> Void
    let session: NSURLSession
 
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - API Methods
    
    func getStudentsLocation(completionHandler: (data: [[String: AnyObject]]?, errorString: String?) -> Void){
        let methodParameters = [
            "order": "-updatedAt",
            "limit": 100,
        ]
        let request = NSMutableURLRequest(URL: NSURL(string:
            ParseClient.studentLocationUrl + escapedParameters(methodParameters))!)
        request.addValue(ParseClient.aplicationID,
            forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseClient.apiKey,
            forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.HTTPMethod = "GET"
        
        let task = session.dataTaskWithRequest(request) {
            (data, response, error) in
            if let error = error {
                completionHandler(data: nil, errorString: error.localizedDescription)
                return
            }
            if let data = data {
                self.parseLocationRequest(data: data, completionHandler: completionHandler)
            } else {
                completionHandler(data: nil, errorString: "Unable to get student location data")
            }
        }
        task.resume()
    }
    
    func queryForStudent(uniqueKey: String?, completionHandler:(data: Student?, errorString: String?) -> Void){
        if let uniqueKey = uniqueKey {
            let methodParameters = [
                "where": "{\"uniqueKey\": \"\(uniqueKey)\"}"
            ]
            let urlString = ParseClient.studentLocationUrl + escapedParameters(methodParameters)
            if let url = NSURL(string: urlString) {
                let request = NSMutableURLRequest(URL: url)
                request.addValue(ParseClient.aplicationID,
                    forHTTPHeaderField: "X-Parse-Application-Id")
                request.addValue(ParseClient.apiKey,
                    forHTTPHeaderField: "X-Parse-REST-API-Key")
                request.HTTPMethod = "GET"
                let task = session.dataTaskWithRequest(request) {
                    (data, response, error) in
                    if let error = error{
                        completionHandler(data: nil, errorString: error.localizedDescription)
                        return
                    }
                    if let data = data {
                        self.parseQueryRequest(data: data, completionHandler: completionHandler)
                    } else {
                        completionHandler(data: nil, errorString: "Unable to get user data")
                    }
                }
                task.resume()
            }
        }
    }
    
    func deleteStudent(objectId: String?, completionHandler:(completed: Bool?,errorString: String?) -> Void ) {
        if objectId == nil {
            completionHandler(completed: false, errorString: "Invalid objectId")
        }
        if let objectId = objectId {
            let urlString = ParseClient.studentLocationUrl + objectId
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            request.HTTPMethod = "DELETE"
            let task = session.dataTaskWithRequest(request) {
                (data, response, error) in
                if let error = error {
                    completionHandler(completed: false, errorString: error.localizedDescription)
                    return
                }
                completionHandler(completed: true, errorString: nil)
            }; task.resume()
        }
    }
    
    func postStudent(student: Student?, completionHandler:(completed: Bool?, errorString: String?) -> Void ){
        if student == nil {
            completionHandler(completed: false, errorString: "Invalid student data")
            return
        }
        if let uniqueKey = student!.uniqueKey, firstName = student!.firstName, lastName = student!.lastName, mapString = student!.mapString, mediaURL = student!.mediaURL, latitude = student!.latitude, longitude = student!.longitude{
            let request = NSMutableURLRequest(URL: NSURL(string: ParseClient.studentLocationUrl)!)
            request.HTTPMethod = "POST"
            request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPBody = "{\"uniqueKey\" : \"\(uniqueKey)\", \"firstName\" : \"\(firstName)\", \"lastName\" : \"\(lastName)\",\"mapString\" : \"\(mapString)\", \"mediaURL\" : \"\(mediaURL)\", \"latitude\" : \(latitude), \"longitude\" : \(longitude)}".dataUsingEncoding(NSUTF8StringEncoding)
            
            let task = session.dataTaskWithRequest(request) {
                (data, response, error) in
                if let error = error {
                    completionHandler(completed: false, errorString: error.localizedDescription)
                    return
                }
                if let data = data {
                    self.parsePostStudentRequest(data: data, completionHandler: completionHandler)
                } else {
                    completionHandler(completed: false, errorString: "Unable to post student data")
                }
            }
            task.resume()
        }
    }
    
    func overwriteStudent(student: Student?, completionHandler:(completed: Bool?, errorString: String?) -> Void){
        if let student = student{
            if let uniqueKey = student.uniqueKey, objectId = student.objectId, firstName = student.firstName, lastName = student.lastName, mapString = student.mapString, mediaURL = student.mediaURL, latitude = student.latitude, longitude = student.longitude{
                let urlString = ParseClient.studentLocationUrl + "/" + objectId
                print(">>>>  Overwrit Student URL is \(urlString)")
                if let url = NSURL(string: urlString){
                    
                    let request = NSMutableURLRequest(URL: url)
                    request.HTTPMethod = "PUT"
                    request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
                    request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.HTTPBody = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}".dataUsingEncoding(NSUTF8StringEncoding)
                    
                    let task = session.dataTaskWithRequest(request){
                        (data, response, error) in
                        
                        if let error = error {
                            print("*** Any error here?")
                            completionHandler(completed: false, errorString: error.localizedDescription)
                            return
                        }
                        if let data = data {
                            print("*** data = data \(data)")
                            self.parseOverwriteRequest(data: data, completionHandler: completionHandler)
                            return
                        }else {
                            completionHandler(completed: false, errorString: "Error: Unable to overwrite")
                            return
                        }
                    }
                    task.resume()
                } else {
                    completionHandler(completed: false, errorString: "Error: Unable to overwrite")
                }
            } else {
                completionHandler(completed: false, errorString: "Error: Unable to overwrite")
            }
        } else {
            completionHandler(completed: false, errorString: "Error: Unable to overwrite")
        }
    }
    
    //MARK: - Helper Methods
    
    func parseLocationRequest(data data: NSData, completionHandler: ParseCompletionHandler){
        do  {
            if let parsedData =
                try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]{
                    if let students = parsedData["results"] as? [[String: AnyObject]]{
                        completionHandler(data: students, errorString: nil)
                        return
                    }
                    if let errorResults = parsedData["error"] as? String{
                        completionHandler(data: nil, errorString: "\(errorResults): validate keys")
                        return
                    }
                    completionHandler(data: nil, errorString: "Unable to load students data")
                    return
            }
        } catch let error as NSError {
            completionHandler(data: nil, errorString: error.localizedDescription)
        }
    }
    
    func parseQueryRequest(data data: NSData, completionHandler: (data: Student?, errorString: String?) -> Void){
        do{
            if let parsedData =
                try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]{
                    if let students = parsedData["results"] as? [[String: AnyObject]]{
                        if let student = students.first{
                            //RETURN THE FIRST STUDENT FOUND IN THE ARRAY OF RESULTS
                            let studentToReturn = Student(dictionary: student)
                            completionHandler(data: studentToReturn, errorString: nil)
                            return
                        } else if students.isEmpty{
                            //STUDENT LOCATIONS FOUND ARE ZERO
                            completionHandler(data: nil, errorString: nil)
                            return
                        }
                    } else {
                        completionHandler(data: nil, errorString: "Unable to retrieve student data")
                    }
            } else {
                completionHandler(data: nil, errorString: "Unable to retrieve student data")
            }
        } catch let error as NSError{
            completionHandler(data: nil, errorString: error.localizedDescription)
        }
    }
    
    func parsePostStudentRequest(data data: NSData, completionHandler:(completed: Bool?, errorString: String?) -> Void) {
        do{
            if let parsedData =
                try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? [String: AnyObject]{
                    if let _ = parsedData["objectId"] as? String{
                        completionHandler(completed: true, errorString: nil)
                        return
                    }
                    completionHandler(completed: false, errorString: "Unable to add location")
            } else {
                completionHandler(completed: false, errorString: "Unable to add location")
            }
        } catch let error as NSError{
            completionHandler(completed: false, errorString: "Error adding location: \(error.localizedDescription)")
        }
    }
    
    func parseOverwriteRequest(data data: NSData, completionHandler: (completed: Bool?, errorString: String?) -> Void){
        
        //var parsedData: AnyObject!
        do {
            //parsedData =
            try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "parseOVerwriteRequest: Could not parse the data as JSON: '\(data)'"]
            completionHandler(completed: nil, errorString: userInfo.description)
            
        }
        
        completionHandler(completed: true, errorString: nil)
    }
    
    /* Helper function: Given a dictionary of parameters,
    convert to a string for a url */
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = escapedValue!.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
}