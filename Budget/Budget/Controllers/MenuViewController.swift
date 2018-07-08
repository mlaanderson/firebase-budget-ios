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

class MenuViewController: UITableViewController {
    var budgetView: BudgetController?

    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var redoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if budgetView != nil {
            undoButton.isEnabled = budgetView?.budget.canUndo ?? false
            redoButton.isEnabled = budgetView?.budget.canRedo ?? false
        }
    }
    
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
    
    @IBAction func undoDidTouch(_ sender: Any) {
        self.dismiss(animated: true) {
            self.budgetView?.undo()
        }
    }
    @IBAction func redoDidTouch(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.budgetView?.redo()
        }
    }
    
    @IBAction func transfersDidTouch(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.budgetView?.showTransfers()
        }
    }
}
