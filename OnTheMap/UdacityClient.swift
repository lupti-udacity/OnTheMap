//
//  UdacityClient.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class UdacityClient: NSObject {
    
    static let sharedInstance = UdacityClient()
    static let loginUrl : String = "https://www.udacity.com/api/session"
    static let publicDataUrl : String = "https://www.udacity.com/api/users/"
    typealias UdacityCompletionHandler =
        (_ data: [String: AnyObject]?, _ errorString: String?) -> Void
    let session: URLSession
    var currentSession: UdacitySession? //** Current user session struct
    var fbLoginManager: FBSDKLoginManager?
    

    override init() {
        session = URLSession.shared
        super.init()
    }
    
    // MARK: - API Request Methods
    // Standard Udacity Login with email and password credential.
    func loginWith(_ email: String, password: String, completionHandler: @escaping UdacityCompletionHandler) {
        
        let request = NSMutableURLRequest(url: URL(string: UdacityClient.loginUrl)! )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"udacity\" : {\"username\" : \"\(email)\", \"password\" : \"\(password)\"}}".data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            // Interesting: No let is needed!!!
            guard error == nil else {
                completionHandler(data: nil, errorString: error!.localizedDescription)
                return
            }
            guard data != nil else {
                completionHandler(data: nil, errorString: "Login Error: Unable to retrieve data")
                return
            }
            let newData = data!.subdata(with: NSMakeRange(5, data!.count - 5))
            self.parseLoginRequest(data: newData, completionHandler: completionHandler)
    
        }) 
        task.resume()
    }
  
    func logoutSession() {
        print("**** Logout Session is called")
        // log out FB 
        fbLoginManager = FBSDKLoginManager.init()
        fbLoginManager?.logOut()
        
        // log out Udacity session with cookies.
        let request = NSMutableURLRequest(url: URL(string: UdacityClient.loginUrl)! )
        request.httpMethod = "DELETE"
        var xsrfCookie: HTTPCookie? = nil
        let sharedCookieStorage = HTTPCookieStorage.shared
        for cookie in sharedCookieStorage.cookies! {
            if cookie.name == "XSRF-TOKEN" {
                xsrfCookie = cookie
                print("cookie found \(xsrfCookie)")
            }
        }
        if let xsrfCookie = xsrfCookie {
            request.setValue(xsrfCookie.value, forHTTPHeaderField: "X-XSRF-TOKEN")
        }
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error != nil { // Handle error…
                print("Error from Udacity Session DELETE failed with \(error)")
                return
            }
            let newData = data!.subdata(with: NSMakeRange(5, data!.count - 5)) /* subset response data! */
            print("******* Udacity Session Deleted with data \(newData)")
            print(NSString(data: newData, encoding: String.Encoding.utf8))
        }) 

        task.resume()
    }

    
    //Facebook login with FB currentAccessToken
    func loginWithFB(_ fbToken: String, completionHandler: @escaping UdacityCompletionHandler) {        
        let request = NSMutableURLRequest(url: URL(string: UdacityClient.loginUrl)! )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{\"facebook_mobile\": {\"access_token\": \"\(fbToken)\"}}".data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            // Interesting: No let is needed!!!
            print("** Facebook Error is \(error?.localizedDescription)")
            
            guard error == nil else {
                completionHandler(data: nil, errorString: error!.localizedDescription)
                return
            }
            print("*** Pass the Error and ready to show the data")
            guard data != nil else {
                completionHandler(data: nil, errorString: "Login Error: Unable to retrieve data")
                return
            }
            let newData = data!.subdata(with: NSMakeRange(5, data!.count - 5))
            print("*** NewData")
            print(NSString(data: newData, encoding: String.Encoding.utf8))
            
            self.parseLoginRequest(data: newData, completionHandler: completionHandler)
        }) 
        task.resume()
    }

    
    func getStudentDataWith(_ uniqueKey: String?,  completionHandler: @escaping UdacityCompletionHandler){
        
        if let uniqueKey = uniqueKey, let url = URL(string: UdacityClient.publicDataUrl + uniqueKey) {
            let request =
            NSMutableURLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "GET"
            
            let task = session.dataTask(with: request, completionHandler: {
                (data, response, error) in
                
                guard error == nil else {
                    completionHandler(data: nil, errorString: error!.localizedDescription)
                    return
                }
                
                let newData = data!.subdata(with: NSMakeRange(5, data!.count - 5))
                self.parseStudentDataRequest(data: newData, completionHandler: completionHandler)
            })
            task.resume()
        } else { completionHandler(nil, "Incorrect Id") }
    }
    
    // MARK: - Helper Methods
    
    func parseLoginRequest(data: Data, completionHandler: UdacityCompletionHandler) {
        do{
            let parsedData =
            try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
            
            guard let accountData = parsedData!["account"] as? [String: AnyObject] else {
                completionHandler(nil, "User does not have Udacity account")
                return
            }
            
            guard let _ = accountData["registered"] as? Bool else{
                completionHandler(nil, "Unable to verify registration")
                return
            }
            
            guard let sessionData = parsedData!["session"] as? [String: AnyObject] else {
                completionHandler(nil, "Login Error: Unable to obtain session")
                return
            }
            
            let dictionary: [String: AnyObject] =
            [  "id": sessionData["id"]!,
                "expiration": sessionData["expiration"]!,
                "uniqueKey": accountData["key"]!,
                "registered": accountData["registered"]!
            ]
            
            currentSession = UdacitySession(dictionary: dictionary as NSDictionary)
            completionHandler(dictionary, nil)
            
        } catch let error as NSError{
                completionHandler(nil, "Login Error: \(error.localizedDescription)")
        }
    }
    
    
    func parseStudentDataRequest(data: Data, completionHandler: UdacityCompletionHandler){
        do{
            let parsedData =
            try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
            
            guard let data = parsedData!["user"] as? [String: AnyObject] else{
                completionHandler(nil, "Unable to get user data")
                return
            }
            
            guard let firstName = (data["first_name"] as? String), let lastName = (data["last_name"] as? String) else {
                completionHandler(nil, "Unable to get user's name")
                return
            }
            
            let dic:[String: AnyObject] = ["firstName": firstName as AnyObject, "lastName":lastName as AnyObject]
            completionHandler(dic, nil)

        } catch let error as NSError{
            completionHandler(nil, error.localizedDescription)
        }
    }
    

}
