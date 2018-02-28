//
//  ImageDetailViewController.swift
//  Photo Phabulous
//
//  Created by Alexi Chryssanthou on 2/23/18.
//  Copyright © 2018 Alexi Chryssanthou. All rights reserved.
//

import UIKit
import Social

class ImageDetailViewController: UIViewController {

    // Mark: - Properties
    var imageShown: UIImage?
    
    // Mark: - Actions
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func shareButton(_ sender: UIBarButtonItem) {
        // Attribution: https://www.hackingwithswift.com/example-code/uikit/how-to-share-content-with-the-social-framework-and-slcomposeviewcontroller
        if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
            if let twitterController = SLComposeViewController(forServiceType: SLServiceTypeTwitter) {
                twitterController.setInitialText("Look at this neat picture!")
                
                twitterController.add(imageShown!)
                //vc.add(URL(string: "https://www.reddit.com"))
                present(twitterController, animated: true)
            }
        } else {
            
            let alert = UIAlertController(title: "Share on Twitter", message: "You are not logged in to your Twitter account.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if (self.navigationController?.navigationBar.isHidden)! {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

}
