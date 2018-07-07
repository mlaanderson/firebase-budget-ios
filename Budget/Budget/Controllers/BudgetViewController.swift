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
    var budget: BudgetController?
    
    @IBOutlet weak var dateTextLabel: UILabel!
    @IBOutlet weak var nameTextLabel: UILabel!
    @IBOutlet weak var amountTextLabel: UILabel!
    @IBOutlet weak var cashTextLabel: UILabel!
    @IBOutlet weak var transferTextLabel: UILabel!
    @IBOutlet weak var paidTextLabel: UILabel!
    @IBOutlet weak var reurringButton: UIButton!
    
    func attachTransaction(_ transaction: Transaction, _ budget: BudgetController) -> Void {
        self.transaction = transaction
        self.budget = budget
        
        self.nameTextLabel?.text = transaction.name
        self.dateTextLabel?.text = Formatters.ViewDate.string(for: Date.parseFb(value: transaction.date))
        self.amountTextLabel?.text = Formatters.Currency.string(from: transaction.amount as NSNumber)
        
        self.cashTextLabel.isHidden = transaction.cash == false
        self.reurringButton.isHidden = transaction.recurring == nil
        self.transferTextLabel.isHidden = transaction.transfer == false
        self.paidTextLabel.isHidden = transaction.paid == false
    }
    
    func setTotal(_ total: Double) {
        self.nameTextLabel?.text = "BALANCE"
        self.cashTextLabel.isHidden = true
        self.reurringButton.isHidden = true
        self.transferTextLabel.isHidden = true
        self.paidTextLabel.isHidden = true
        self.amountTextLabel.text = Formatters.Currency.string(from: total as NSNumber)
    }
    
    
    @IBAction func recurringDidTouch(_ sender: UIButton) {
        guard
        self.budget != nil,
        self.transaction != nil,
        self.transaction?.recurring != nil
            else { return }
        self.budget?.editRecurring(self.transaction!.recurring!)
    }
}

class BudgetController: UITableViewController, UIPopoverPresentationControllerDelegate {
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
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var newButton: UIBarButtonItem!
    @IBOutlet weak var recurringButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    
    //MARK: Actions
    @IBAction func undoDidTouch(_ sender: UIBarButtonItem) {
        guard
        self.budget != nil,
        self.budget.canUndo
            else { return }
        
        self.budget.undo()
    }
    
    @IBAction func redoDidTouch(_ sender: UIBarButtonItem) {
        guard
            self.budget != nil,
            self.budget.canRedo
            else { return }
        
        self.budget.redo()
    }
    
    @IBAction func editButtonDidTouch(_ sender: UIBarButtonItem) {
        if self.activeTransaction != nil {
            performSegue(withIdentifier: self.transactionEditorSegue, sender: nil)
        }
    }

    @IBAction func recurringButtonDidTouch(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "recurringSegue", sender: nil)
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
                let transactions = items.filter( { item in
                    return item.category == self.Categories[indexPath.section]
                })
                
                if transactions.count > indexPath.row {
                    cell.attachTransaction(transactions[indexPath.row], self)
                }
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
        switch segue.identifier {
        case "transactionEditorSegue":
            if let transactionNavigator = segue.destination as? UINavigationController {
                    if let transactionEditor = transactionNavigator.topViewController as? TransactionEditorControler {
                    transactionEditor.categories = self.budget.config.categories
                    transactionEditor.transactions = self.budget.transactions

                    transactionEditor.setTransaction(self.activeTransaction)
                    
                    self.activeTransaction = nil
                    self.editButton.isEnabled = false
                }
            }
            break
        case "viewMenuSegue":
            if let menu = segue.destination as? MenuViewController {
                menu.budgetView = self
                menu.modalPresentationStyle = .popover
                menu.popoverPresentationController!.delegate = self
            }
            break
        case "datePickerSegue":
            if let vc = segue.destination as? DatePickerDialog {
                vc.attachBudget(periods: self.periods, current: self.budget.period, budget: self.budget, parentView: self)
                vc.modalPresentationStyle = .popover
                vc.popoverPresentationController!.delegate = self
            }
            break
        case "recurringSegue":
            if let nvc = segue.destination as? UINavigationController {
                if let vc = nvc.topViewController as? RecurringEditorController {
                    vc.budget = self.budget
                    vc.transaction = sender as? RecurringTransaction
                }
            }
            break
        default:
            break
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    func editRecurring(_ id: String) {
        self.budget.recurrings.load(key: id) { transaction in
            self.performSegue(withIdentifier: "recurringSegue", sender: transaction)
        }
    }

    //MARK: Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.menuButton.title = "\u{2699}\u{0000fe0e}"
        self.showSpinner()
        
        // verify the user
        Auth.auth().addStateDidChangeListener() { auth, user in
            if (user == nil) {
                self.dismiss(animated: true, completion: nil)
            } else {
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
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Data functions
    
    func showTransfers() -> Void {
        let title = "Transfer \(budget.transactions.Transfer < 0 ? "into" : "from") Savings"
        let message = "Transfer \(Formatters.Currency.string(from: abs(budget.transactions.Transfer) as NSNumber) ?? "$0.00")"
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(dialog, animated: true, completion: nil)
    }
    
    func showCash() -> Void {
        let title = "Cash Withdrawl"
        var message = ""
        let cash = budget.transactions.Cash
        
        if cash.hundreds != 0 {
            message += "\(cash.hundreds) x $100 bill\(cash.hundreds == 1 ? "" : "s") \t(\(Formatters.Currency.string(from: Double(cash.hundreds) * 100.0 as NSNumber) ?? ""))\n"
        }
        
        if cash.fifties != 0 {
            message += "\(cash.fifties) x $50 bill\(cash.fifties == 1 ? "\t" : "s")\t(\(Formatters.Currency.string(from: Double(cash.fifties) * 50.0 as NSNumber) ?? ""))\n"
        }
        
        if cash.twenties != 0 {
            message += "\(cash.twenties) x $20 bill\(cash.twenties == 1 ? "\t" : "s")\t(\(Formatters.Currency.string(from: Double(cash.twenties) * 20.0 as NSNumber) ?? ""))\n"
        }
        
        if cash.tens != 0 {
            message += "\(cash.tens) x $10 bill\(cash.tens == 1 ? "\t" : "s")\t(\(Formatters.Currency.string(from: Double(cash.tens) * 10.0 as NSNumber) ?? ""))\n"
        }
        
        if cash.fives != 0 {
            message += "\(cash.fives) x $5 bill\(cash.fives == 1 ? "\t" : "s")\t(\(Formatters.Currency.string(from: Double(cash.fives) * 5.0 as NSNumber) ?? ""))\n"
        }
        
        if cash.ones != 0 {
            message += "\(cash.ones) x $1 bill\(cash.ones == 1 ? "\t" : "s")\t(\(Formatters.Currency.string(from: Double(cash.ones) as NSNumber) ?? ""))\n"
        }
        
        if cash.quarters != 0 {
            message += "\(cash.quarters) x Quarter\(cash.quarters == 1 ? "" : "s")\t(\(Formatters.Currency.string(from: Double(cash.quarters) * 0.25 as NSNumber) ?? ""))\n"
        }
        
        if cash.dimes != 0 {
            message += "\(cash.dimes) x Dime\(cash.dimes == 1 ? "" : "s")\t(\(Formatters.Currency.string(from: Double(cash.dimes) * 0.1 as NSNumber) ?? ""))\n"
        }
        
        if cash.nickels != 0 {
            message += "\(cash.nickels) x Nickel\(cash.nickels == 1 ? "" : "s")\t(\(Formatters.Currency.string(from: Double(cash.nickels) * 0.05 as NSNumber) ?? ""))\n"
        }
        
        if cash.pennies != 0 {
            message += "\(cash.pennies) x Penn\(cash.pennies == 1 ? "y" : "ies")\t(\(Formatters.Currency.string(from: Double(cash.pennies) * 0.01 as NSNumber) ?? ""))\n"
        }
        
        message += "\n\t\t\t\(Formatters.Currency.string(from: Double(cash) as NSNumber) ?? "No cash withdrawal")"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let terms = NSTextTab.columnTerminators(for: NSLocale.current)
        let tabStop0 = NSTextTab(textAlignment: .left, location: 0, options: [.columnTerminators:terms])
        let tabStop1 = NSTextTab(textAlignment: .right , location: 300, options: [.columnTerminators:terms])
        let dialog = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        paragraphStyle.addTabStop(tabStop0)
        paragraphStyle.addTabStop(tabStop1)
        
        let messageText = NSMutableAttributedString(
            string: message,
            attributes: [
                .paragraphStyle : paragraphStyle
            ]
        )
        dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        dialog.setValue(messageText, forKey: "attributedMessage")
        self.present(dialog, animated: true, completion: nil)
    }
    
    func startListeners() -> Void {
        let _ = self.budget.on(.loadPeriod, handler: self.loadTransactions)
        let _ = self.budget.transactions.on(.childChanged, handler: self.changeTransaction)
        let _ = self.budget.transactions.on(.childRemoved, handler: self.removeTransaction)
        let _ = self.budget.transactions.on(.childAdded, handler: self.addTransaction)
        
        let _ = self.budget.on(.historyChanged) { _ in
            self.undoButton.isEnabled = self.budget.canUndo
            self.redoButton.isEnabled = self.budget.canRedo
        }
    }
    
    func addTransaction(_ data: Historical<Transaction>?) {
        if data != nil {
            if self.budget.transactions.Start! <= data!.current.date && data!.current.date <= self.budget.transactions.End! {
                self.items.append(data!.current)
                sortTransactions()
                self.Categories = self.budget.Categories
            }
            self.total = self.budget.transactions.total
            self.tableView.reloadData()
        }
//        self.budget.transactions.getTotal() { total in
//            self.total = total
//            self.tableView.reloadData()
//        }
    }
    
    func removeTransaction(_ data: Historical<Transaction>?) {
        if data != nil {
            if let idx = self.items.map({ $0.id }).index(of: data!.current.id) {
                self.items.remove(at: idx)
                sortTransactions()
                self.Categories = self.budget.Categories
            }
            self.total = self.budget.transactions.total
            self.tableView.reloadData()
        }
//        self.budget.transactions.getTotal() { total in
//            self.total = total
//            self.tableView.reloadData()
//        }
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
            self.Categories = self.budget.Categories
            self.total = self.budget.transactions.total
            self.tableView.reloadData()
        }
//        self.budget.transactions.getTotal() { total in
//            self.total = total
//            self.tableView.reloadData()
//        }
    }
    
    func loadTransactions(_: AnyObject?) {
        self.items = self.budget.transactions.List
        self.dateLabel.title = Formatters.ViewDate.string(from: self.budget.period.start) + " - " + Formatters.ViewDateYear.string(from: self.budget.period.end)

        sortTransactions()

        self.Categories = self.budget.Categories
        self.total = self.budget.transactions.total
        self.tableView.reloadData()

        if self.spinner != nil {
            UIViewController.removeSpinner(spinner: self.spinner!)
            self.spinner = nil
        }
        
        self.menuButton.isEnabled = true
        self.prevButton.isEnabled = self.budget.CanGoBack
        self.nextButton.isEnabled = true
        self.dateLabel.isEnabled = true
        self.newButton.isEnabled = true
        self.recurringButton.isEnabled = true
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
