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
        
        loginUsername.delegate = self
        loginPassword.delegate = self
        
        Auth.auth().addStateDidChangeListener() { auth, user in

            if (user != nil) {
                user!.getIDTokenResult(forcingRefresh: true) { token, error in
                    if error != nil {
                        do {
                            try Auth.auth().signOut()
                        } catch (_) {
                            self.loginPassword.text = ""
                            self.loginUsername.text = ""
                            self.loginUsername.becomeFirstResponder()
                        }
                    } else {
                        self.performSegue(withIdentifier: self.loginToBudget, sender: nil)
                        self.loginUsername.text = nil
                        self.loginPassword.text = nil
                    }
                }

            } else {
                self.loginPassword.text = ""
                self.loginUsername.text = ""
                self.loginUsername.becomeFirstResponder()
            }
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                performLogin()
                return false
            default:
                return true
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
        
        login(withEmail: email, password: password)
    }
    
    func login(withEmail: String, password: String) {
        Auth.auth().signIn(withEmail: withEmail, password: password){ (user, error) in
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func testUser() {
        print(Auth.auth().currentUser?.uid ?? "logged out")
    }

    
    //MARK: Actions
    @IBAction func loginButton(_ sender: UIButton) {
        performLogin()
    }
}

