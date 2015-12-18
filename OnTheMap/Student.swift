//
//  Student.swift
//  OnTheMap
//
//  Created by Lupti on 12/15/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import Foundation

struct Student {
    
    var objectId: String?
    var uniqueKey: String?
    var firstName: String?
    var lastName: String?
    var mapString: String?
    var mediaURL: String?
    var latitude: Double?
    var longitude: Double?
    var updatedAt: NSDate?
    
    init(dictionary: NSDictionary) {
        objectId = dictionary["objectId"] as? String
        uniqueKey = dictionary["uniqueKey"] as? String
        firstName = dictionary["firstName"] as? String
        lastName = dictionary["lastName"] as? String
        mapString = dictionary["mapString"] as? String
        mediaURL = dictionary["mediaURL"] as? String
        latitude = dictionary["latitude"] as? Double
        longitude = dictionary["longitude"] as? Double
        uniqueKey = dictionary["uniqueKey"] as? String

        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyy-MM-dd'T'HH:mm:ss'.'SSSZ"
        if let updatedString = dictionary["updatedAt"] as? String {
            updatedAt = formatter.dateFromString(updatedString)
        }
    }
    
    // Construct a full name string 
    var fullName : String {
        get {
            var firstName = ""
            if self.firstName != nil {
                firstName = self.firstName!
            }
            
            var lastName = ""
            if self.lastName != nil {
                lastName = self.lastName!
            }
            
            return "\(firstName) \(lastName)"
        }
    }
    
}