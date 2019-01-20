//
//  UserViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 2.11.2018.
//  Copyright © 2018 Berkay Cesur. All rights reserved.
//

import UIKit
import Firebase

class UserMailListTableViewController: UITableViewController {
    
    @IBOutlet var mailsTableView: UITableView!
    
    var items: [Mail] = []
    var user: User!
    let ref = Database.database().reference(withPath: "users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)
            print(user.uid)
            self.ref.child(user.uid).child("mails").observe(.value, with: { snapshot in
                if snapshot.exists() {
                    var newItems: [Mail] = []
                    for child in snapshot.children {
                        if let snapshot = child as? DataSnapshot,
                            let mailItem = Mail(snapshot: snapshot) {
                            newItems.append(mailItem)
                        }
                    }
                    self.items = newItems
                    self.tableView.reloadData()
                    
                } else {
                    print("UserListTableViewController - There is no mail for the user!")
                    self.tableView.reloadData()
                }
            })
        }
        mailsTableView.dataSource = self
        mailsTableView.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let mailItem = items[indexPath.row]
        
        cell.textLabel?.text = mailItem.receiver
        cell.detailTextLabel?.text = mailItem.text
        if mailItem.checked {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let mailItem = items[indexPath.row]
            items.remove(at: indexPath.row)
            mailItem.ref?.removeValue()
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !items[indexPath.row].checked && !items[indexPath.row].downloadUrl.isEmpty {
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            let mailItem = items[indexPath.row]
            let toggledCompletion = !mailItem.checked
            toggleCellCheckbox(cell, isCompleted: toggledCompletion)
            mailItem.ref?.updateChildValues([
                "checked": toggledCompletion
                ])
        }
        performSegue(withIdentifier: "showdetail", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DetailedMailViewController {
            destination.mail = items[(mailsTableView.indexPathForSelectedRow?.row)!]
            destination.user = user
            mailsTableView.deselectRow(at: mailsTableView.indexPathForSelectedRow!, animated: true)
            
        }

    }
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = .black
            cell.detailTextLabel?.textColor = .black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = .gray
            cell.detailTextLabel?.textColor = .gray
        }
    }
}
