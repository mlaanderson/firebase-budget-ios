//
//  RecurringEditorController.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/4/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

enum RecurringRows: Int {
    case period, start, end, category, name, deposit, cash, transfer, amount, notes
}

class RecurringStruct {
    var id: String?
    
    var amount: Double = 0.0
    var cash: Bool = false
    var category: String = ""
    var end: Date = Date.today() + "1 year"
    var name: String = ""
    var note: String?
    var period: Timespan = Timespan.parse(value: "1 month")!
    var start: Date = Date.today()
    var transfer: Bool = false
    
    init() {}
    
    init(_ data: RecurringTransaction) {
        id = data.id
        amount = data.amount
        cash = data.cash
        category = data.category
        end = Date.parseFb(value: data.end)!
        name = data.name
        note = data.note
        period = Timespan.parse(value: data.period)!
        start = Date.parseFb(value: data.start)!
        transfer = data.transfer
    }
    
    func asObject() -> [AnyHashable: Any] {
        var result: [AnyHashable:Any] = [:]
        
        result["id"] = self.id
        result["amount"] = self.amount
        result["category"] = self.category
        result["end"] = self.end.toFbString()
        result["name"] = self.name
        result["period"] = String(self.period)
        result["start"] = self.start.toFbString()
        result["note"] = self.note
        result["cash"] = self.cash
        result["transfer"] = self.transfer
        
        return result
    }
}

class RecurringEditorController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    var budget: BudgetData?
    var transaction: RecurringTransaction?
    var data: RecurringStruct = RecurringStruct()
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var periodTextField: UITextField!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var depositSwitch: UISwitch!
    @IBOutlet weak var cashSwitch: UISwitch!
    @IBOutlet weak var transferSwitch: UISwitch!
    @IBOutlet weak var amountTextField: CurrencyField!
    @IBOutlet weak var noteTextView: UITextView!
    
    //MARK: PickerView delegates
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if self.budget?.config.categories == nil { return 0 }
        return self.budget!.config.categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if self.budget?.config.categories == nil { return nil}
        return self.budget!.config.categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        data.category = self.budget!.config.categories[row]
        categoryLabel.text = "Category: \(data.category)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if transaction != nil {
            data = RecurringStruct(transaction!)
            data.id = transaction!.id!
            deleteButton.isEnabled = true
        } else {
            if self.budget != nil {
                data.category = self.budget?.config.categories[0] ?? ""
            }
            deleteButton.isEnabled = false
        }
        
        periodTextField.text = String(data.period)
        startDateLabel.text = "Starting: \(Formatters.ViewDateYear.string(from: data.start))"
        endDateLabel.text = "Ending: \(Formatters.ViewDateYear.string(from: data.end))"
        categoryLabel.text = "Category: \(self.data.category)"
        nameTextField.text = data.name
        depositSwitch.isOn = data.amount > 0
        cashSwitch.isOn = data.cash
        transferSwitch.isOn = data.transfer
        amountTextField.text = Formatters.Currency.string(from: abs(data.amount) as NSNumber)
        noteTextView.text = data.note ?? ""

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        categoryPicker.dataSource = self
        categoryPicker.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.budget != nil {
            let catIndex = self.budget?.config.categories.firstIndex(of: data.category) ?? 0
            self.categoryPicker.selectRow(catIndex, inComponent: 0, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == RecurringRows.notes.rawValue {
            return 200
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        startDatePicker.isHidden = true
        endDatePicker.isHidden = true
        categoryPicker.isHidden = true
        switch RecurringRows(rawValue: indexPath.row) ?? .cash {
        case .start:
            startDatePicker.isHidden = false
            startDatePicker.date = data.start
            break;
        case .end:
            endDatePicker.isHidden = false
            endDatePicker.date = data.end
            break
        case .category:
            categoryPicker.isHidden = false
            break
        default:
            break
        }
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    @IBAction func saveDidTouch(_ sender: UIBarButtonItem) {
        
        if let ts = Timespan.parse(value: periodTextField.text ?? "") {
            if ts.days.count > 0 || ts.months != 0 || ts.years != 0 || ts.seconds != 0 {
                data.period = ts
            }
        }
        data.category = (budget?.config.categories[categoryPicker.selectedRow(inComponent: 0)])!
        data.name = nameTextField.text!
        data.amount = (depositSwitch.isOn ? 1 : -1) * amountTextField.doubleValue
        data.cash = cashSwitch.isOn
        data.transfer = transferSwitch.isOn
        data.note = noteTextView.text
        
        
        if data.id != nil {
            // update the current
            transaction?.period = String(data.period)
            transaction?.start = data.start.toFbString()
            transaction?.end = data.end.toFbString()
            transaction?.category = data.category
            transaction?.amount = data.amount
            transaction?.cash = data.cash
            transaction?.transfer = data.transfer
            transaction?.note = data.note
        } else {
            transaction = RecurringTransaction(data: data.asObject() as AnyObject)
        }
        
        budget?.saveRecurring(transaction!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func trashDidTouch(_ sender: UIBarButtonItem) {
        if transaction != nil {
            budget!.removeRecurring(transaction!)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelDidTouch(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func periodDidChange(_ sender: UITextField) {
        if let ts = Timespan.parse(value: sender.text ?? "") {
            if ts.days.count > 0 || ts.months != 0 || ts.years != 0 || ts.seconds != 0 {
                data.period = ts
            } else {
                sender.text = String(data.period)
            }
        } else if sender.text != nil && sender.text! != "" {
            sender.text = String(data.period)
        }
    }
    
    @IBAction func startDateDidChange(_ sender: UIDatePicker) {
        data.start = sender.date
        startDateLabel.text = "Starting: \(Formatters.ViewDateYear.string(from: sender.date))"
    }
    
    @IBAction func endDateDidChange(_ sender: UIDatePicker) {
        data.end = sender.date
        endDateLabel.text = "Ending: \(Formatters.ViewDateYear.string(from: sender.date))"
    }
    
    @IBAction func nameDidChange(_ sender: UITextField) {
        data.name = sender.text ?? ""
    }
    
    @IBAction func depositDidChange(_ sender: UISwitch) {
        data.amount = (sender.isOn ? 1 : -1) * abs(data.amount)
    }
    
    @IBAction func cashDidChange(_ sender: UISwitch) {
        data.cash = sender.isOn
    }
    
    @IBAction func transferDidChange(_ sender: UISwitch) {
        data.transfer = sender.isOn
    }
    
    @IBAction func amountDidChange(_ sender: CurrencyField) {
        data.amount = (depositSwitch.isOn ? 1 : -1) * sender.doubleValue
    }
    
}
