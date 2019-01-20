//
//  Mail.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 2.12.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import Foundation
import Firebase

struct Mail {
    
    let ref: DatabaseReference?
    //let sender: String!
    let receiver: String!
    //Whole text without parsing for now
    let text: String!
    let checked: Bool
    var downloadUrl: String!
    
    init(receiver: String, text: String, checked: Bool, downloadUrl: String) {
        self.ref = nil
        self.text = text
        self.receiver = receiver
        self.checked = checked
        self.downloadUrl = downloadUrl
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let receiver = value["receiver"] as? String,
            let text = value["text"] as? String,
            let checked = value["checked"] as? Bool,
            let downloadUrl = value["downloadUrl"] as? String else {
                return nil
        }
        self.ref = snapshot.ref
        self.receiver = receiver
        self.text = text
        self.checked = checked
        self.downloadUrl = downloadUrl
    }
    
    func toAnyObject() -> Any {
        return [
            "receiver": receiver,
            "text": text,
            "checked": checked,
            "downloadUrl": downloadUrl
        ]
    }
    
}
