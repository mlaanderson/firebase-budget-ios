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

class LoginController: UIViewController, UITextFieldDelegate {
    
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

    //MARK: TextFieldDelegates
    func textFieldChouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
            case loginUsername:
                loginUsername.resignFirstResponder()
                loginPassword.becomeFirstResponder()
                return false
                break
            case loginPassword:
                loginPassword.resignFirstResponder()
                performLogin()
                return false
                break
            default:
                return true
                break
        }
    }

    func performLogin() {
        guard
            let email = loginUsername.text,
            let password = loginPassword.text,
            email.count > 0,
            password.count > 0
            else {
                // go back to the username field
                loginUsername.becomeFirstResponder()
                return
            }
        
        Auth.auth().signIn(withEmail: email, password: password){ (user, error) in
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    
    //MARK: Actions
    @IBAction func loginButton(_ sender: UIButton) {
        performLogin()
    }

    @IBAction func loginSignupButton(_ sender: UIButton) {
        print("Signup Button Pressed\n");
    }

}

