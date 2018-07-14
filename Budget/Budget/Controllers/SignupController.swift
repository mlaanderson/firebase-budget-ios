//
//  SignupController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/10/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class SignupController: UIViewController, UITextFieldDelegate {


    //MARK: Properties
    @IBOutlet weak var loginUsername: UITextField!
    @IBOutlet weak var loginPassword: UITextField!
    @IBOutlet weak var signupButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        loginUsername.delegate = self
        loginPassword.delegate = self
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if (user != nil) {
                self.dismiss(animated: true)
            }
        }
    }

    @IBAction func signupDidTouch(_ sender: UIButton) {
        performSignup()
    }
    
    @IBAction func fieldsDidChange(_ sender: UITextField) {
        guard
        loginUsername.text != nil,
        let password = loginPassword.text,
        password.count >= 6
            else {
                signupButton.isEnabled = false
                return
        }
        signupButton.isEnabled = true
    }
    
    //MARK: TextFieldDelegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
            case loginUsername:
                loginUsername.resignFirstResponder()
                loginPassword.becomeFirstResponder()
                return false
            case loginPassword:
                loginPassword.resignFirstResponder()
                performSignup()
                return false
            default:
                return true
        }
    }

    // Business Logic
    func performSignup() {
        // firebase restricts passwords to 6 chars or more
        guard
            let username = loginUsername.text,
            let password1 = loginPassword.text
            else { return }

        guard password1.count >= 6
            else { 
                flashMessage("Password must be 6 characters or longer") {
                    self.loginPassword.text = ""
                    self.loginPassword.becomeFirstResponder()
                }
                return
            }

        Auth.auth().createUser(withEmail: username, password: password1) { (user, error) in
            if error != nil {
                // handle the error here
                let alert = UIAlertController(title: "Login Failed", message: error!.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    func flashMessage(_ message: String, title: String = "Error", completion:(() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: completion)
    }
}
