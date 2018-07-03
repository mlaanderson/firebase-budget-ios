//
//  TransactionEditorNavigationController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/2/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

class TransactionEditorNavigationController : UINavigationController {
    var transaction: Transaction?
    var transactions: Transactions?
    var categories: [String]?
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "transactionEditorSegue" {
            if let transactionEditor = segue.destination as? TransactionEditorControler {
                transactionEditor.categories = self.categories
                transactionEditor.transactions = self.transactions
                
                transactionEditor.setTransaction(self.transaction)
            }
        }
    }
}
