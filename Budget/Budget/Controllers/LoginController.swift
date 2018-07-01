//
//  ViewController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/6/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class LoginController: UIViewController {
    
    let loginToBudget = "loginToBudget"
    var budget: BudgetData?
    
    //MARK: Properties
    @IBOutlet weak var loginUsername: UITextField!
    @IBOutlet weak var loginPassword: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if (user != nil) {
                self.performSegue(withIdentifier: self.loginToBudget, sender: nil)
                self.loginUsername.text = nil
                self.loginPassword.text = nil
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    //MARK: Actions
    @IBAction func loginButton(_ sender: UIButton) {
        guard
            let email = loginUsername.text,
            let password = loginPassword.text,
            email.count > 0,
            password.count > 0
            else {
                return
        }
        
        Auth.auth().signIn(withEmail: email, password: password){ (user, error) in
            // ...
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }

    }

    @IBAction func loginSignupButton(_ sender: UIButton) {
        print("Signup Button Pressed\n");
        
    }

}

