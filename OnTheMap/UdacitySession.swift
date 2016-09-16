//
//  UdacitySession.swift
//  OnTheMap
//
//  Created by Lupti on 12/28/15.
//  Copyright © 2015 lupti. All rights reserved.
//

import Foundation
/* Udacity Session Struct */

struct UdacitySession {
    
    var registered: Bool?
    var uniqueKey: String?
    var id: String?
    var expiration: NSDate?

    init(dictionary: NSDictionary) {
        
        registered = dictionary["registered"] as? Bool
        uniqueKey = dictionary["uniqueKey"] as? String
        id = dictionary["id"] as? String
        expiration = dictionary["expiration"] as? NSDate

        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.'SSSZ"
        if let expirationString = dictionary["expiration"] as? String {
            expiration = formatter.dateFromString(expirationString)
        }
    }
}
