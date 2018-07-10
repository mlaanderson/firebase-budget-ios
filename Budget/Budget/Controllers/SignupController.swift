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
    @IBOutlet weak var loginPasswordVerify: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            if (user != nil) {
                self.dismiss(animated: true, completion: nil)
            }
        }
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
                loginPasswordVerify.becomeFirstResponder()
                return false
                break
            case loginPasswordVerify:
                loginPasswordVerify.resignFirstResponder()
                performSignup()
                break
            default:
                return true
                break
        }
    }

    // Business Logic
    func performSignup() {
        // firebase restricts passwords to 6 chars or more
        guard
            let username = loginUsername.text,
            let password1 = loginPassword.text,
            let password2 = loginPasswordVerify.text
            else { return }

        guard password1.count >= 6
            else { 
                flashMessage("Password must be 6 characters or longer") {
                    loginPassword.text = ""
                    loginPasswordVerify.text = ""
                    loginPassword.becomeFirstResponder()
                }
                return
            }

        guard password1 == password2
            else {
                flashMessage("Passwords do not match") {
                    loginPassword.text = ""
                    loginPasswordVerify.text = ""
                    loginPassword.becomeFirstResponder()
                }
                return
            }

        Auth.auth().createUser(withEmail: username, password: password1) { user, error in
            if error != nil {
                // handle the error here
            }
        }
    }

    func flashMessage(_ message: String, title: String = "Error", completion:@escaping (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: completion)
    }
}