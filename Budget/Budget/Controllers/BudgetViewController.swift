//
//  BudgetViewController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/9/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import UIKit

import Firebase
import FirebaseDatabase
import FirebaseAuth

class BudgetTableViewCell : UITableViewCell {
    var transaction: Transaction?
    
    @IBOutlet weak var dateTextLabel: UILabel!
    @IBOutlet weak var nameTextLabel: UILabel!
    @IBOutlet weak var amountTextLabel: UILabel!
    @IBOutlet weak var recurringTextLabel: UILabel!
    @IBOutlet weak var cashTextLabel: UILabel!
    @IBOutlet weak var transferTextLabel: UILabel!
    @IBOutlet weak var paidTextLabel: UILabel!
    
    
    func attachTransaction(_ transaction: Transaction) -> Void {
        self.transaction = transaction
        
        self.nameTextLabel?.text = transaction.name
        self.dateTextLabel?.text = Formatters.ViewDate.string(for: Date.parseFb(value: transaction.date))
        self.amountTextLabel?.text = Formatters.Currency.string(from: transaction.amount as NSNumber)
        
        self.cashTextLabel.isHidden = transaction.cash == false
        self.recurringTextLabel.isHidden = transaction.recurring == nil
        self.transferTextLabel.isHidden = transaction.transfer == false
        self.paidTextLabel.isHidden = transaction.paid == false
    }
    
    func setTotal(_ total: Double) {
        self.nameTextLabel?.text = "BALANCE"
        self.cashTextLabel.isHidden = true
        self.recurringTextLabel.isHidden = true
        self.transferTextLabel.isHidden = true
        self.amountTextLabel.text = Formatters.Currency.string(from: total as NSNumber)
    }
    
}

class BudgetController: UITableViewController {
    var transactionEditorSegue = "transactionEditorSegue"
    var budget: BudgetData!
    var user : User!
    var ref : DatabaseReference!
    var dateFormatter = DateFormatter()
    var periodStart : Date?
    var periodEnd : Date?
    var items: [Transaction] = []
    var activeTransaction : Transaction?
    var total: Double = 0
    var Categories: [String] = []
    var periods = [Period]()
    var spinner: UIView?
    
    var Ready : Bool {
        get {
            return self.budget != nil && self.budget.Ready
        }
    }
    
    //MARK: Outlets
    
    @IBOutlet weak var dateLabel: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var prevButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var newButton: UIBarButtonItem!
    
    //MARK: Actions
    
    @IBAction func editButtonDidTouch(_ sender: UIBarButtonItem) {
        if self.activeTransaction != nil {
            performSegue(withIdentifier: self.transactionEditorSegue, sender: nil)
        }
    }

    @IBAction func dateLabelDidTouch(_ sender: UIBarButtonItem) {

        let vc = (storyboard?.instantiateViewController(withIdentifier: "PeriodPickerDialog"))! as! DatePickerDialog
        vc.attachBudget(periods: self.periods, current: self.budget.period, budget: self.budget, parentView: self)
        self.present(vc, animated: true)
    }
    
    @IBAction func logoutDidTouch(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        } catch (let error) {
            print("Auth signout error: \(error)")
        }
    }
    
    @IBAction func nextPeriodDidTouch(_ sender: UIBarButtonItem) {
        showSpinner()
        self.budget.goForward()
    }
    
    @IBAction func prevPeriodDidTouch(_ sender: UIBarButtonItem) {
        showSpinner()
        self.budget.goBack()
    }
    

    @IBAction func btnAddTransactionDidTouch(_ sender: UIBarButtonItem) {
        self.activeTransaction = nil
        performSegue(withIdentifier: self.transactionEditorSegue, sender: nil)
    }
    
    //MARK: UITableView Delegate methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.Ready {
            return self.budget.Categories.count + 1
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.Ready {
            if section >= self.Categories.count { return "" }
            return "\(self.Categories[section])"
            
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.Ready {
            if section >= self.Categories.count { return 1 }
            return self.items.filter( { item in
                return item.category == self.Categories[section]
            }).count
        }
        return 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! BudgetTableViewCell
        if self.Ready {
            if indexPath.section < self.Categories.count {
                let transaction = items.filter( { item in
                    return item.category == self.Categories[indexPath.section]
                })[indexPath.row]
                
                cell.attachTransaction(transaction)
            } else {
                cell.setTotal(self.total)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section < self.Categories.count {
            return .delete
        }
        return .none
    }

    override func tableView(_ tableView: UITableView, commit editingStyle:  UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if self.Ready {
            if indexPath.section < self.Categories.count {
                let transaction = items.filter( { item in
                    return item.category == self.Categories[indexPath.section]
                })[indexPath.row]
                
                let deleteAlert = UIAlertController(title: "Are you sure?", message: "Delete this transaction?", preferredStyle: UIAlertControllerStyle.alert)
                
                deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                    self.budget.removeTransaction(transaction)
                }))
                
                deleteAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                
                present(deleteAlert, animated: true, completion: nil)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section >= self.Categories.count { return nil }
        return indexPath
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.activeTransaction = items.filter( { item in
            return item.category == self.Categories[indexPath.section]
        })[indexPath.row]
        
        self.editButton.isEnabled = self.activeTransaction != nil
    }
    
    //MARK: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "transactionEditorSegue" {
            if let transactionNavigator = segue.destination as? UINavigationController {
                    if let transactionEditor = transactionNavigator.topViewController as? TransactionEditorControler {
                    transactionEditor.categories = self.budget.config.categories
                    transactionEditor.transactions = self.budget.transactions

                    transactionEditor.setTransaction(self.activeTransaction)
                    
                    self.activeTransaction = nil
                    self.editButton.isEnabled = false
                }
            }
        }
    }

    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.showSpinner()
        let user = Firebase.Auth.auth().currentUser
        self.budget = BudgetData(Database.database().reference().child((user?.uid)!))
       
        var _ = self.budget!.on(.configRead) { nilval in
            var date = self.budget.config.startDate
            
            self.periods = []
            
            repeat {
                self.periods.append(self.budget.config.calculatePeriod(date: date))
                date = date + self.budget.config.length
            } while date < Date.today() + "5 years"
            
            self.startListeners()
            self.budget!.gotoDate(Date.today())
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Data functions
    
    func startListeners() -> Void {
        let _ = self.budget.on(.loadPeriod, handler: self.loadTransactions)
        let _ = self.budget.transactions.on(.childChanged, handler: self.changeTransaction)
        let _ = self.budget.transactions.on(.childRemoved, handler: self.removeTransaction)
        let _ = self.budget.transactions.on(.childAdded, handler: self.addTransaction)
    }
    
    func addTransaction(_ data: Historical<Transaction>?) {
        if data != nil {
            if self.budget.transactions.Start! <= data!.current.date && data!.current.date <= self.budget.transactions.End! {
                self.items.append(data!.current)
                sortTransactions()
            }
        }
        self.Categories = self.budget.Categories
        self.budget.transactions.getTotal() { total in
            self.total = total
            self.tableView.reloadData()
        }
    }
    
    func removeTransaction(_ data: Historical<Transaction>?) {
        if data != nil {
            if let idx = self.items.map({ $0.id }).index(of: data!.current.id) {
                self.items.remove(at: idx)
                sortTransactions()
            }
        }
        self.Categories = self.budget.Categories
        self.budget.transactions.getTotal() { total in
            self.total = total
            self.tableView.reloadData()
        }
    }
        
    func changeTransaction(_ data: Historical<Transaction>?) {
        if data != nil {
            if let idx = self.items.map({ $0.id }).index(of: data!.current.id) {
                self.items.remove(at: idx)
            }
            if self.budget.transactions.Start! <= data!.current.date && data!.current.date <= self.budget.transactions.End! {
                self.items.append(data!.current)
            }
            sortTransactions()
        }
        self.Categories = self.budget.Categories
        self.budget.transactions.getTotal() { total in
            self.total = total
            self.tableView.reloadData()
        }
    }
    
    func loadTransactions(_: AnyObject?) {
        self.items = self.budget.transactions.List
        self.dateLabel.title = Formatters.ViewDate.string(from: self.budget.period.start) + " - " + Formatters.ViewDateYear.string(from: self.budget.period.end)

        sortTransactions()

        self.Categories = self.budget.Categories
        self.budget.transactions.getTotal() { total in
            self.total = total
            self.tableView.reloadData()
            
            if self.spinner != nil {
                UIViewController.removeSpinner(spinner: self.spinner!)
                self.spinner = nil
            }
            
            self.logoutButton.isEnabled = true
            self.prevButton.isEnabled = self.budget.CanGoBack
            self.nextButton.isEnabled = true
            self.dateLabel.isEnabled = true
            self.newButton.isEnabled = true
        }
    }
    
    func sortTransactions() {
        self.items.sort(by: { t1, t2 in
            if self.budget.config.categories.index(of: t1.category)! < self.budget.config.categories.index(of: t2.category)! {
                return true
            }
            
            if t1.category == t2.category && t1.name < t2.name {
                return true
            }
            
            if t1.category == t2.category && t1.name == t2.name && t1.amount < t2.amount {
                return true
            }
            
            return false
        })
    }
    
    //MARK UI Functions
    func showSpinner() {
        self.spinner = UIViewController.displaySpinner(onView: self.view)
    }
}
