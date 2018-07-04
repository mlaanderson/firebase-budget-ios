//
//  MenuViewController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/4/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth

class MenuViewController: UIViewController {
    var budgetView: BudgetController?


    @IBAction func logoutDidTouch(_ sender: UIButton) {
        self.dismiss(animated: true) {
            do {
                try Auth.auth().signOut()
            } catch (let error) {
                print("Auth signout error: \(error)")
            }
        }
    }
    
    @IBAction func cashDidTouch(_ sender: Any) {
        self.dismiss(animated: true) {
            self.budgetView?.showCash()
        }
    }
    
    @IBAction func transfersDidTouch(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.budgetView?.showTransfers()
        }
    }
}
