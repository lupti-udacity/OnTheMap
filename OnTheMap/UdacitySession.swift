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
    var expiration: Date?

    init(dictionary: NSDictionary) {
        
        registered = dictionary["registered"] as? Bool
        uniqueKey = dictionary["uniqueKey"] as? String
        id = dictionary["id"] as? String
        expiration = dictionary["expiration"] as? Date

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'.'SSSZ"
        if let expirationString = dictionary["expiration"] as? String {
            expiration = formatter.date(from: expirationString)
        }
    }
}
