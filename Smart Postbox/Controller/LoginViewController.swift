//
//  ViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 2.11.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    //Segue Identifier
    let loginToHome = "LoginToHome"

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        emailTextField.delegate = self
        pwdTextField.delegate = self
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if user != nil {
                self.performSegue(withIdentifier: self.loginToHome, sender: nil)
                self.emailTextField.text = nil
                self.pwdTextField.text = nil
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.resignFirstResponder()
            pwdTextField.becomeFirstResponder()
        } else if textField == pwdTextField {
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    @IBAction func signInButton(_ sender: Any) {
        if emailTextField.text!.isEmpty || pwdTextField.text!.isEmpty {
            print("Isn't it empty dawg?")
            let alertController = UIAlertController(title: "Error", message: "Please enter your email!", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            present(alertController,animated: true,completion: nil)
            
        } else {
            print("It is not empty dawg?")
            Auth.auth().signIn(withEmail: emailTextField.text!, password: pwdTextField.text!) { (user, error) in
                if user != nil {
                    //Print into the console if successfully logged in
                    print("You have successfully logged in")
                    
                    self.performSegue(withIdentifier: self.loginToHome, sender: nil)
                    
                    
                }
                
                if error != nil {
                    
                    //Tells the user that there is an error and then gets firebase to tell them the error
                    let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                    
                    let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    alertController.addAction(defaultAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    @IBAction func unwindToLogin(_ unwindSegue: UIStoryboardSegue) {}
    
}

