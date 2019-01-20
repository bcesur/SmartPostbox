//
//  HomeViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 1.12.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import MessageUI

class HomeViewController: UIViewController {
    
    var user: User!
    let ref = Database.database().reference(withPath: "users")
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
        }
    }
    
    @IBAction func logOutToolbarButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("Sign out successful")
            self.dismiss(animated: true, completion: nil)
        } catch ( _) {
            print("Sign out failed")
        }
    }
}
