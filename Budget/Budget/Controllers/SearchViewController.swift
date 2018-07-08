//
//  SearchViewController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/8/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

class SearchTableViewCell : UITableViewCell {
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    func setTranscation(_ transaction: Transaction) {
        dateLabel.text = Formatters.ViewDateYear.string(from: Date.parseFb(value: transaction.date) ?? Date.today())
        nameLabel.text = transaction.name
        amountLabel.text = Formatters.Currency.string(from: transaction.amount as NSNumber)
    }
    
}

class SearchViewController : UITableViewController {
    var budget: BudgetData?
    var Categories: [String] = []
    var items: [Transaction] = []
    
    @IBOutlet weak var searchField: UITextField!
    
    @IBAction func editingChanged(_ sender: UITextField, forEvent event: UIEvent) {
        guard
            let phrase = searchField.text,
            phrase.count > 0
            else {
                return
        }
        
        search(phrase)
    }
    
    @IBAction func searchDidTouch(_ sender: Any) {
        guard
            let phrase = searchField.text,
            phrase.count > 0
            else {
                return
        }
        
        search(phrase)
    }
    
    @IBAction func cancelDidTouch(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.budget?.Categories.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section >= self.Categories.count { return nil }
        return "\(self.Categories[section])"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.Categories.count { return 0 }
        return self.items.filter( { item in
            return item.category == self.Categories[section]
        }).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath) as! SearchTableViewCell
        if indexPath.section < self.Categories.count {
            let transactions = items.filter( { item in
                return item.category == self.Categories[indexPath.section]
            })

            if transactions.count > indexPath.row {
                cell.setTranscation(transactions[indexPath.row])
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section < self.Categories.count {
            let transactions = items.filter( { item in
                return item.category == self.Categories[indexPath.section]
            })
            
            if transactions.count > indexPath.row {
                if let date = Date.parseFb(value: transactions[indexPath.row].date) {
                    self.dismiss(animated: true) {
                        self.budget?.gotoDate(date)
                    }
                }
            }
        }
    }
    
    func search(_ phrase: String) {
        self.budget?.transactions.search(search: phrase) { items in
            self.items = items
            self.Categories = Array(Set(items.map({ $0.category })))
            self.tableView.reloadData()
        }
    }
}
