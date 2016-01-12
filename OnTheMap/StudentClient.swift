//
//  StudentClient.swift
//  OnTheMap
//
//  Created by Lupti on 1/10/16.
//  Copyright © 2016 lupti. All rights reserved.
//

/* Data store for Student struct
*/


import UIKit

class StudentClient: NSObject {

    static let sharedInstance = StudentClient()
    var students: [Student]? = [Student]()
    // studentArray for holding refreshed student records from the Parse server
    var studentArray: [Student]? = [Student]()
    var currentStudent: Student? = Student()
    var onTheMap : Bool?  //** If student loction is posted this is true
    
    override init() {
        super.init()
    }

    
}
