//
//  LastIntroPageControllerViewController.swift
//  
//
//  Created by Mike Kari Anderson on 7/21/18.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class LastIntroPageControllerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // we only hit this when going to the main screen
        guard let user = Auth.auth().currentUser?.uid else { return }
        Database.database().reference(withPath: user).child("config/showWizard").setValue(false)
    }

}
