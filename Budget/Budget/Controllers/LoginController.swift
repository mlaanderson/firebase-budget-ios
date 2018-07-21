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

enum LoginSegues: String {
    case
        LoginToBudget = "loginToBudget",
        ShowIntro = "introWizardSegue"
}

class LoginController: UIViewController, UITextFieldDelegate {
    
    var budget: BudgetData?
    var spinner: UIView?
    
    //MARK: Properties
    @IBOutlet weak var loginUsername: UITextField!
    @IBOutlet weak var loginPassword: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        loginUsername.delegate = self
        loginPassword.delegate = self
        
        Auth.auth().addStateDidChangeListener() { auth, user in
            self.showSpinner()
            if (user != nil) {
                user!.getIDTokenResult(forcingRefresh: true) { token, error in
                    if error != nil {
                        do {
                            try Auth.auth().signOut()
                        } catch (_) {
                            self.loginPassword.text = ""
                            self.loginUsername.text = ""
                            self.loginUsername.becomeFirstResponder()
                            self.hideSpinner()
                        }
                    } else {
                        // check to see if the wizard should be shown
                        Database.database().reference(withPath: user!.uid).child("config/showWizard").observeSingleEvent(of: .value) { snapshot in
                            let showWizard = snapshot.value as? Bool
                            guard showWizard == true else {
                                self.performSegue(withIdentifier: LoginSegues.LoginToBudget.rawValue, sender: nil)
                                self.hideSpinner()
                                return
                            }
                            self.performSegue(withIdentifier: LoginSegues.ShowIntro.rawValue, sender: nil)
                            self.hideSpinner()
                        }
                        self.loginUsername.text = nil
                        self.loginPassword.text = nil
                    }
                }

            } else {
                self.loginPassword.text = ""
                self.loginUsername.text = ""
                self.loginUsername.becomeFirstResponder()
                self.hideSpinner()
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

    //MARK UI Functions
    func showSpinner() {
        self.spinner = UIViewController.displaySpinner(onView: self.view)
    }
    
    func hideSpinner() {
        guard self.spinner != nil else { return }
        UIViewController.removeSpinner(spinner: self.spinner!)
        self.spinner = nil
    }
    
    //MARK: Actions
    @IBAction func loginButton(_ sender: UIButton) {
        performLogin()
    }
}

