//
//  PreferencesViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 17.01.2019.
//  Copyright © 2019 Berkay Cesur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class PreferencesViewController: UITableViewController {
    
    var user: User!
    var items: [UserPreferences] = []
    let ref = Database.database().reference(withPath: "users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            self.ref.child(user.uid).child("preferences").observe(.value, with: { snapshot in
                if snapshot.exists() {
                    var newItems: [UserPreferences] = []
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                            let prefItem = UserPreferences(snapshot: snapshot) {
                            newItems.append(prefItem)
                        }
                    }
                    self.items = newItems
                    self.tableView.reloadData()
                }
                else {
                    print("PreferenceViewController - There is no preference for the user in the db.")
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let preference = items[indexPath.row]
        
        cell.textLabel?.text = preference.sender
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let prefItem = items[indexPath.row]
            items.remove(at: indexPath.row)
            prefItem.ref?.removeValue()
        }
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        let alert = UIAlertController(title: "Add a Preference",
                                      message: "Expect a post from the sender below",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let textField = alert.textFields?.first,
                let text = textField.text else { return }
            
            
            let prefItem = UserPreferences(sender: text)
            self.items.append(prefItem)
            let prefRef = self.ref.child(self.user.uid).child("preferences")
            let prefId = prefRef.childByAutoId()
            prefId.setValue(prefItem.toAnyObject())
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
}
