//
//  TransactionEditorController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/18/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

enum TableRows : Int {
    case date = 0, category, name, deposit, cash, transfer, check, amount, paid, note
}

struct TransactionData {
    var id: String?
    var amount: Double = 0.0
    var cash: Bool
    var category: String
    var check: String?
    var date: String
    var name: String
    var note: String?
    var paid: Bool
    var recurring: String?
    var transfer: Bool
    
    var deposit : Bool {
        get { return amount >= 0 }
    }
    
    static func defaultTransaction() -> TransactionData {
        return TransactionData(id: nil, amount: 0, cash: false, category: "", check: nil, date: Date.today().toFbString(), name: "", note: nil, paid: false, recurring: nil, transfer: false)
    }
    
    static func fromTransaction(_ data: Transaction) -> TransactionData {
        return TransactionData(id: data.id, amount: data.amount, cash: data.cash, category: data.category, check: data.check, date: data.date, name: data.name, note: data.note, paid: data.paid, recurring: data.recurring, transfer: data.transfer)
    }
    
    func asObject() -> [AnyHashable: Any] {
        var result: [AnyHashable:Any] = [:]
        
        result["amount"] = self.amount
        result["category"] = self.category
        result["date"] = self.date
        result["name"] = self.name
        result["check"] = self.check
        result["note"] = self.note
        result["recurring"] = self.recurring
        result["cash"] = self.cash
        result["paid"] = self.paid
        result["transfer"] = self.transfer
        
        return result
    }
}

class TransactionEditorControler: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {

    private var dateCellExpanded: Bool = false
    private var catCellExpanded: Bool = false
    
    
    var data: TransactionData?
    var budget: BudgetData?
    var transaction: Transaction?
    var categories: [String]?
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var lblDate: UILabel!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var txtName: UITextField!
    @IBOutlet weak var swDeposit: UISwitch!
    @IBOutlet weak var swCash: UISwitch!
    @IBOutlet weak var swTransfer: UISwitch!
    @IBOutlet weak var txtCheck: UITextField!
    @IBOutlet weak var txtAmount: UITextField!
    @IBOutlet weak var swPaid: UISwitch!
    @IBOutlet weak var txtNote: UITextView!
    @IBOutlet weak var recurringButton: UIBarButtonItem!
    
    func setTransaction(_ transaction: Transaction?) {
        if transaction != nil {
            self.data = TransactionData.fromTransaction(transaction!)
        } else {
            self.data = TransactionData.defaultTransaction()
            self.data?.category = self.categories?[0] ?? "Income"
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == self.txtAmount {
            let allowedCharacters = CharacterSet.decimalDigits
            let characterSet = CharacterSet(charactersIn: textField.text!)
            return allowedCharacters.isSuperset(of: characterSet)
        }
        return false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.categories == nil { return 0 }
        return self.categories!.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if self.categories == nil { return nil}
        return self.categories![row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.data != nil && self.categories != nil {
            data!.category = self.categories![row]
            lblCategory.text = "Category: " + self.categories![row]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        // setup the row heights
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        self.categoryPicker.dataSource = self
        self.categoryPicker.delegate = self

        // set the loaded transaction
        if self.data != nil {
            self.datePicker.date = Date.parseFb(value: (self.data?.date)!)!
            
            lblDate.text = "Date: " + Formatters.EditDate.string(from: self.datePicker.date)
            lblCategory.text = "Category: " + data!.category
            
            txtName.text = data!.name
            swDeposit.isOn = data!.amount > 0
            swCash.isOn = data!.cash
            swTransfer.isOn = data!.transfer
            txtCheck.text = data?.check ?? ""
            txtAmount.text = Formatters.NumberEdit.string(from: abs(data!.amount) as NSNumber)
            swPaid.isOn = data!.paid
            txtNote.text = data?.note ?? ""
            recurringButton.isEnabled = data?.recurring != nil
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.categories != nil {
            let selectedCategory = self.data?.category ?? self.categories![0]
            let catIndex = self.categories?.firstIndex(of: selectedCategory) ?? 0

            self.categoryPicker.selectRow(catIndex, inComponent: 0, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch TableRows(rawValue: indexPath.row) ?? .cash {
        case .amount:
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.txtAmount.becomeFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .cash:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .category:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.catCellExpanded = !self.catCellExpanded
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = !self.categoryPicker.isHidden
            break
        case .check:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.becomeFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .date:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = !self.datePicker.isHidden
            self.categoryPicker.isHidden = true
            break
        case .deposit:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .name:
            self.txtAmount.resignFirstResponder()
            self.txtName.becomeFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .note:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.becomeFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .paid:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        case .transfer:
            self.txtAmount.resignFirstResponder()
            self.txtName.resignFirstResponder()
            self.txtCheck.resignFirstResponder()
            self.txtNote.resignFirstResponder()
            self.datePicker.isHidden = true
            self.categoryPicker.isHidden = true
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch TableRows(rawValue: indexPath.row) ?? .cash {
        case .note:
            return 200
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    //MARK: Actions
    
    @IBAction func datePicker(_ sender: UIDatePicker) {
        self.data!.date = self.datePicker.date.toFbString()
        lblDate.text = "Date: " + Formatters.EditDate.string(from: self.datePicker.date)
        self.data!.date = self.datePicker.date.toFbString()
    }
    
    @IBAction func recurringDidTouch(_ sender: UIBarButtonItem) {
        print("Touched recurring edit")
    }
    
    @IBAction func cancelDidTouch(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }
    
    @IBAction func saveDidTouch(_ sender: UIBarButtonItem) {
        // pick up the valuse from the controls
        guard
        var transData = self.data,
        let transactions = self.budget?.transactions
        else {
            return
        }
        transData.name = self.txtName.text ?? ""
        transData.amount = Double(truncating: Formatters.Currency.number(from: self.txtAmount.text!) ?? transData.amount as NSNumber) * (self.swDeposit.isOn ? 1 : -1)
        transData.cash = self.swCash.isOn && transData.amount < 0
        transData.transfer = self.swTransfer.isOn
        transData.check = self.txtCheck.text
        transData.paid = self.swPaid.isOn
        
        
        if transData.id != nil {
            // existing transaction
            transactions.load(key: transData.id!) { transaction in
                transaction.amount = transData.amount
                transaction.cash = transData.cash
                transaction.category = transData.category
                transaction.check = transData.check
                transaction.date = transData.date
                transaction.name = transData.name
                transaction.note = transData.note
                transaction.paid = transData.paid
                transaction.recurring = transData.recurring
                transaction.transfer = transData.transfer
                
                self.budget!.saveTransaction(transaction)
                
                self.dismiss(animated: true)
            }
        } else {
            if let transaction = Transaction(data: transData.asObject() as AnyObject) {
                self.budget!.saveTransaction(transaction)
                self.dismiss(animated: true)
            }
        }
    }
}
