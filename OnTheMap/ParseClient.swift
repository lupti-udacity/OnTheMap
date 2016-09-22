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
        (_ data: [[String: AnyObject]]?, _ errorString: String?) -> Void
    let session: URLSession
 
    override init() {
        session = URLSession.shared
        super.init()
    }
    
    // MARK: - API Methods
    
    func getStudentsLocation(_ completionHandler: @escaping (_ data: [[String: AnyObject]]?, _ errorString: String?) -> Void){
        let methodParameters = [
            "order": "-updatedAt",
            "limit": 100,
        ] as [String : Any]
        let request = NSMutableURLRequest(url: URL(string:
            ParseClient.studentLocationUrl + escapedParameters(methodParameters as [String : AnyObject]))!)
        request.addValue(ParseClient.aplicationID,
            forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue(ParseClient.apiKey,
            forHTTPHeaderField: "X-Parse-REST-API-Key")
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: {
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
        }) 
        task.resume()
    }
    
    func queryForStudent(_ uniqueKey: String?, completionHandler:@escaping (_ data: Student?, _ errorString: String?) -> Void){
        if let uniqueKey = uniqueKey {
            let methodParameters = [
                "where": "{\"uniqueKey\": \"\(uniqueKey)\"}"
            ]
            let urlString = ParseClient.studentLocationUrl + escapedParameters(methodParameters as [String : AnyObject])
            if let url = URL(string: urlString) {
                let request = NSMutableURLRequest(url: url)
                request.addValue(ParseClient.aplicationID,
                    forHTTPHeaderField: "X-Parse-Application-Id")
                request.addValue(ParseClient.apiKey,
                    forHTTPHeaderField: "X-Parse-REST-API-Key")
                request.httpMethod = "GET"
                let task = session.dataTask(with: request, completionHandler: {
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
                }) 
                task.resume()
            }
        }
    }
    
    func deleteStudent(_ objectId: String?, completionHandler:@escaping (_ completed: Bool?,_ errorString: String?) -> Void ) {
        if objectId == nil {
            completionHandler(false, "Invalid objectId")
        }
        if let objectId = objectId {
            let urlString = ParseClient.studentLocationUrl + "/" + objectId
            let request = NSMutableURLRequest(url: URL(string: urlString)!)
            request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            request.httpMethod = "DELETE"
            let task = session.dataTask(with: request, completionHandler: {
                (data, response, error) in
                if let error = error {
                    completionHandler(completed: false, errorString: error.localizedDescription)
                    return
                }
                completionHandler(completed: true, errorString: nil)
            }) ; task.resume()
        }
    }
    
    func postStudent(_ student: Student?, completionHandler:@escaping (_ completed: Bool?, _ errorString: String?) -> Void ){
        if student == nil {
            completionHandler(false, "Invalid student data")
            return
        }
        if let uniqueKey = student!.uniqueKey, let firstName = student!.firstName, let lastName = student!.lastName, let mapString = student!.mapString, let mediaURL = student!.mediaURL, let latitude = student!.latitude, let longitude = student!.longitude{
            let request = NSMutableURLRequest(url: URL(string: ParseClient.studentLocationUrl)!)
            request.httpMethod = "POST"
            request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
            request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = "{\"uniqueKey\" : \"\(uniqueKey)\", \"firstName\" : \"\(firstName)\", \"lastName\" : \"\(lastName)\",\"mapString\" : \"\(mapString)\", \"mediaURL\" : \"\(mediaURL)\", \"latitude\" : \(latitude), \"longitude\" : \(longitude)}".data(using: String.Encoding.utf8)
            
            let task = session.dataTask(with: request, completionHandler: {
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
            }) 
            task.resume()
        }
    }
    
    func overwriteStudent(_ student: Student?, completionHandler:@escaping (_ completed: Bool?, _ errorString: String?) -> Void){
        if let student = student{
            if let uniqueKey = student.uniqueKey, let objectId = student.objectId, let firstName = student.firstName, let lastName = student.lastName, let mapString = student.mapString, let mediaURL = student.mediaURL, let latitude = student.latitude, let longitude = student.longitude{
                let urlString = ParseClient.studentLocationUrl + "/" + objectId
                print(">>>>  Overwrit Student URL is \(urlString)")
                if let url = URL(string: urlString){
                    
                    let request = NSMutableURLRequest(url: url)
                    request.httpMethod = "PUT"
                    request.addValue(ParseClient.aplicationID, forHTTPHeaderField: "X-Parse-Application-Id")
                    request.addValue(ParseClient.apiKey, forHTTPHeaderField: "X-Parse-REST-API-Key")
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = "{\"uniqueKey\": \"\(uniqueKey)\", \"firstName\": \"\(firstName)\", \"lastName\": \"\(lastName)\",\"mapString\": \"\(mapString)\", \"mediaURL\": \"\(mediaURL)\",\"latitude\": \(latitude), \"longitude\": \(longitude)}".data(using: String.Encoding.utf8)
                    
                    let task = session.dataTask(with: request, completionHandler: {
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
                    })
                    task.resume()
                } else {
                    completionHandler(false, "Error: Unable to overwrite")
                }
            } else {
                completionHandler(false, "Error: Unable to overwrite")
            }
        } else {
            completionHandler(false, "Error: Unable to overwrite")
        }
    }
    
    //MARK: - Helper Methods
    
    func parseLocationRequest(data: Data, completionHandler: ParseCompletionHandler){
        do  {
            if let parsedData =
                try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]{
                    if let students = parsedData["results"] as? [[String: AnyObject]]{
                        completionHandler(students, nil)
                        return
                    }
                    if let errorResults = parsedData["error"] as? String{
                        completionHandler(nil, "\(errorResults): validate keys")
                        return
                    }
                    completionHandler(nil, "Unable to load students data")
                    return
            }
        } catch let error as NSError {
            completionHandler(nil, error.localizedDescription)
        }
    }
    
    func parseQueryRequest(data: Data, completionHandler: (_ data: Student?, _ errorString: String?) -> Void){
        do{
            if let parsedData =
                try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]{
                    if let students = parsedData["results"] as? [[String: AnyObject]]{
                        if let student = students.first{
                            //RETURN THE FIRST STUDENT FOUND IN THE ARRAY OF RESULTS
                            let studentToReturn = Student(dictionary: student as NSDictionary)
                            completionHandler(studentToReturn, nil)
                            return
                        } else if students.isEmpty{
                            //STUDENT LOCATIONS FOUND ARE ZERO
                            completionHandler(nil, nil)
                            return
                        }
                    } else {
                        completionHandler(nil, "Unable to retrieve student data")
                    }
            } else {
                completionHandler(nil, "Unable to retrieve student data")
            }
        } catch let error as NSError{
            completionHandler(nil, error.localizedDescription)
        }
    }
    
    func parsePostStudentRequest(data: Data, completionHandler:(_ completed: Bool?, _ errorString: String?) -> Void) {
        do{
            if let parsedData =
                try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject]{
                    if let _ = parsedData["objectId"] as? String{
                        completionHandler(true, nil)
                        return
                    }
                    completionHandler(false, "Unable to add location")
            } else {
                completionHandler(false, "Unable to add location")
            }
        } catch let error as NSError{
            completionHandler(false, "Error adding location: \(error.localizedDescription)")
        }
    }
    
    func parseOverwriteRequest(data: Data, completionHandler: (_ completed: Bool?, _ errorString: String?) -> Void){
        
        //var parsedData: AnyObject!
        do {
            //parsedData =
            try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "parseOVerwriteRequest: Could not parse the data as JSON: '\(data)'"]
            completionHandler(nil, userInfo.description)
            
        }
        
        completionHandler(true, nil)
    }
    
    /* Helper function: Given a dictionary of parameters,
    convert to a string for a url */
    func escapedParameters(_ parameters: [String : AnyObject]) -> String {
        var urlVars = [String]()
        for (key, value) in parameters {
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = escapedValue!.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
}
