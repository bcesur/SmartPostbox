//
//  MailSender.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 16.01.2019.
//  Copyright © 2019 Berkay Cesur. All rights reserved.
//

import Foundation
import Firebase

struct UserPreferences {
    
    let ref: DatabaseReference?
    let sender: String
    
    init(sender: String) {
        self.ref = nil
        self.sender = sender
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let sender = value["sender"] as? String else {
                return nil
        }
        
        self.ref = snapshot.ref
        self.sender = sender
    }
    
    func toAnyObject() -> Any {
        return [
            "sender": sender
        ]
    }
}
