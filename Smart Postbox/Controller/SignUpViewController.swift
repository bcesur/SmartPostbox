//
//  SignUpViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 30.11.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    
    //var user: User!
    let ref = Database.database().reference(withPath: "users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        nameTextField.delegate = self
        emailTextField.delegate = self
        pwdTextField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            textField.resignFirstResponder()
            emailTextField.becomeFirstResponder()
        } else if textField == emailTextField {
            textField.resignFirstResponder()
            pwdTextField.becomeFirstResponder()
        } else if textField == pwdTextField {
            textField.resignFirstResponder()
        }
        return true
    }
    
    fileprivate func addPredefinedUserPreferences(_ userRef: DatabaseReference) {
        let predefinedUserPreferences = ["AOK", "Deutsche Bank", "CommerzBank", "Sparkasse","Kreisverwaltungsreferat"]
        let prefRef = userRef.child("preferences")
        for up in predefinedUserPreferences {
            let prefItem = UserPreferences(sender: up)
            let details = prefRef.childByAutoId()
            details.setValue(prefItem.toAnyObject())
        }
    }
    
    @IBAction func signUpButton(_ sender: Any) {
        if emailTextField.text == "" || pwdTextField.text == "" || nameTextField.text == "" {
            let alertController = UIAlertController(title: "Error", message: "Please enter your email and password", preferredStyle: .alert)
            
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            
            present(alertController, animated: true, completion: nil)
            
        } else {
            Auth.auth().createUser(withEmail: emailTextField.text!, password: pwdTextField.text!) { (user, error) in
                
                if user != nil {
                    print("You have successfully signed up")
                    self.performSegue(withIdentifier: "SignUpToHome", sender: nil)
                    let userRef = self.ref.child((user?.user.uid)!)
                    let userItem = User(uid: (user?.user.uid)!, name: self.nameTextField.text!, email: self.emailTextField.text!)
                    userRef.setValue(userItem.toAnyObject())
                    self.addPredefinedUserPreferences(userRef)
                }
                
                if error != nil {
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        segue.destination.
//    }
    
}
