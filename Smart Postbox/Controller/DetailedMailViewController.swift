//
//  DetailedMailViewController.swift
//  Smart Postbox
//
//  Created by Berkay Cesur on 19.01.2019.
//  Copyright © 2019 Berkay Cesur. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class DetailedMailViewController: UIViewController {
    
    @IBOutlet weak var mailPicUIImageView: UIImageView!
    
    var user: User?
    var mail: Mail?
    let storage = Storage.storage()
     let ref = Database.database().reference(withPath: "users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener { auth, user in
            guard let user = user else { return }
            self.user = User(authData: user)

        }
        if (!(mail?.downloadUrl.isEmpty)!) {
            mailPicUIImageView.loadImageUsingCacheWithUrlString((mail?.downloadUrl)!)
        } else {
            mailPicUIImageView.loadImageUsingCacheWithUrlString("https://firebasestorage.googleapis.com/v0/b/smartpostbox-fd86d.appspot.com/o/defaultErrorPic.jpg?alt=media&token=6cb201bd-d72b-4532-b0f2-49387daf177f")
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

let imageCache = NSCache<NSString, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(_ urlString: String) {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: urlString as NSString) as? UIImage {
            self.image = cachedImage
            return
        }
        
        //otherwise fire off a new download
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
            
            //download hit an error so lets return out
            if let error = error {
                print(error)
                return
            }
            
            DispatchQueue.main.async(execute: {
                
                if let downloadedImage = UIImage(data: data!) {
                    imageCache.setObject(downloadedImage, forKey: urlString as NSString)
                    
                    self.image = downloadedImage
                }
            })
            
        }).resume()
    }
    
}
