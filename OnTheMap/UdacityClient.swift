//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit

class UdacityClient: NSObject {
    
    static let sharedInstance = UdacityClient()
    static let loginUrl : String = "https://www.udacity.com/api/session"
    static let publicDataUrl : String = "https://www.udacity.com/api/users/"
    typealias UdacityCompletionHandler =
        (data: [String: AnyObject]?, errorString: String?) -> Void
    let session: NSURLSession
    var currentSession: UdacitySession? //** Current user session struct
    
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - API Request Methods
    
    func loginWith(email: String, password: String, completionHandler: UdacityCompletionHandler) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: UdacityClient.loginUrl)! )
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"udacity\" : {\"username\" : \"\(email)\", \"password\" : \"\(password)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            // Interesting: No let is needed!!!
            guard error == nil else {
                completionHandler(data: nil, errorString: error!.localizedDescription)
                return
            }
            /*  if let error = error  {
                completionHandler(data: nil, errorString: error.localizedDescription)
                return
            }
            */
            
            guard data != nil else {
                completionHandler(data: nil, errorString: "Login Error: Unable to retrieve data")
                return
            }
            let newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5))
            self.parseLoginRequest(data: newData, completionHandler: completionHandler)
    
        }
        task.resume()
    }
  
    func logoutSession() {
        
        let request = NSMutableURLRequest(URL: NSURL(string: UdacityClient.loginUrl)! )
        request.HTTPMethod = "DELETE"
        var xsrfCookie: NSHTTPCookie? = nil
        let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" { xsrfCookie = cookie }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil { // Handle error…
                print("Error from Udacity Session DELETE failed with \(error)")
                return
            }
            let newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5)) /* subset response data! */
            print("******* Udacity Session Deleted with data \(newData)")
            print(NSString(data: newData, encoding: NSUTF8StringEncoding))
        }

        task.resume()
    }

    
    //Facebook login with FB currentAccessToken
    func loginWithFB(fbToken: String, completionHandler: UdacityCompletionHandler) {
        
        let request = NSMutableURLRequest(URL: NSURL(string: UdacityClient.loginUrl)! )
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = "{\"facebook_mobile\": {\"access_token\": \"(fbToken)\"}}".dataUsingEncoding(NSUTF8StringEncoding)
        
        let task = session.dataTaskWithRequest(request) {(data, response, error) in
            // Interesting: No let is needed!!!
            print("** Facebook Error is \(error?.localizedDescription)")
            
            guard error == nil else {
                completionHandler(data: nil, errorString: error!.localizedDescription)
                return
            }
            /*  if let error = error  {
            completionHandler(data: nil, errorString: error.localizedDescription)
            return
            }
            */
            print("*** Pass the Error and ready to show the data")
            guard data != nil else {
                completionHandler(data: nil, errorString: "Login Error: Unable to retrieve data")
                return
            }
            let newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5))
            print("*** NewData")
            print(NSString(data: newData, encoding: NSUTF8StringEncoding))
            
            self.parseLoginRequest(data: newData, completionHandler: completionHandler)
            
            
        }
        task.resume()
    }

    
    func getStudentDataWith(uniqueKey: String?,  completionHandler: UdacityCompletionHandler){
        
        if let uniqueKey = uniqueKey, url = NSURL(string: UdacityClient.publicDataUrl + uniqueKey) {
            let request =
            NSMutableURLRequest(URL: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "GET"
            
            let task = session.dataTaskWithRequest(request){
                (data, response, error) in
                
                guard error == nil else {
                    completionHandler(data: nil, errorString: error!.localizedDescription)
                    return
                }
                
                let newData = data!.subdataWithRange(NSMakeRange(5, data!.length - 5))
                self.parseStudentDataRequest(data: newData, completionHandler: completionHandler)
            }
            task.resume()
        } else { completionHandler(data: nil, errorString: "Incorrect Id") }
    }
    
    // MARK: - Helper Methods
    
    func parseLoginRequest(data data: NSData, completionHandler: UdacityCompletionHandler) {
        do{
            let parsedData =
            try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
            
            guard let accountData = parsedData!["account"] as? [String: AnyObject] else {
                completionHandler(data: nil, errorString: "User does not have Udacity account")
                return
            }
            
            guard let _ = accountData["registered"] as? Bool else{
                completionHandler(data: nil, errorString:"Unable to verify registration")
                return
            }
            
            guard let sessionData = parsedData!["session"] as? [String: AnyObject] else {
                completionHandler(data: nil, errorString: "Login Error: Unable to obtain session")
                return
            }
            
            let dictionary: [String: AnyObject] =
            [  "id": sessionData["id"]!,
                "expiration": sessionData["expiration"]!,
                "uniqueKey": accountData["key"]!,
                "registered": accountData["registered"]!
            ]
            
            currentSession = UdacitySession(dictionary: dictionary)
            completionHandler(data: dictionary, errorString: nil)
            
        } catch let error as NSError{
                completionHandler(data: nil, errorString: "Login Error: \(error.localizedDescription)")
        }
    }
    
    
    func parseStudentDataRequest(data data: NSData, completionHandler: UdacityCompletionHandler){
        do{
            let parsedData =
            try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments) as? NSDictionary
            print("* Udacity student data parseStudentDataRequest is \(parsedData)")
            guard let data = parsedData!["user"] as? [String: AnyObject] else{
                completionHandler(data: nil, errorString: "Unable to get user data")
                return
            }
            
            guard let firstName = (data["first_name"] as? String), lastName = (data["last_name"] as? String) else {
                completionHandler(data: nil, errorString: "Unable to get user's name")
                return
            }
            
            let dic:[String: AnyObject] = ["firstName": firstName, "lastName":lastName]
            completionHandler(data: dic, errorString: nil)

        } catch let error as NSError{
            completionHandler(data: nil, errorString: error.localizedDescription)
        }
    }
    
}