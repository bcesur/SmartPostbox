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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func logOutToolbarButton(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            print("Sign out successful")
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            print("Sign out failed")
        }
    }
}
