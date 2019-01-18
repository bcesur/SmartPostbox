//
//  User.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 30.11.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import Foundation
import Firebase

struct User {
    
    let ref = Database.database().reference(withPath: "users")
    
    let uid: String
    let name: String
    let email: String
    
    init(authData: Firebase.User) {
        //name = authData.displayName!
        uid = authData.uid
        email = authData.email!
        self.name = ""
    }
    
    
    
    init(uid: String, name: String, email: String) {
        self.uid = uid
        self.email =  email
        self.name = name
    }
    
    func toAnyObject() -> Any {
        return [
            "uid": uid,
            "email": email,
            "name": name
        ]
    }
    
}
