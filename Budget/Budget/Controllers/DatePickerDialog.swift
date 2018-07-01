//
//  DatePickerDialog.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/1/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

class DatePickerDialog: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    private var periods = [Period]()
    private var current: Int = -1
    private var budget: BudgetData?
    private var parentView: BudgetController?
    
    func attachBudget(periods: [Period], current: Period, budget: BudgetData, parentView: BudgetController) {
        self.periods = periods
        self.budget = budget
        self.parentView = parentView
        
        self.current = periods.index(where: { $0.start == current.start }) ?? 0
    }
    
    //MARK Outlets
    @IBOutlet weak var periodPicker: UIPickerView!
    @IBOutlet weak var okButton: UIButton!
    
    
    //Mark Actions
    @IBAction func didTouchOKButton(_ sender: UIButton) {
        let idx = self.periodPicker.selectedRow(inComponent: 0)
        
        self.dismiss(animated: true)
        
        self.budget?.gotoDate(self.periods[idx].start + "1 day")
    }
    
    @IBAction func todayDidTouch(_ sender: UIButton) {
        self.dismiss(animated: true)
        self.budget?.gotoDate(Date.today())
    }
    
    override func viewDidLoad() {
        view.isOpaque = false;
        periodPicker.dataSource = self
        periodPicker.delegate = self
        
        self.okButton.isEnabled = true
        periodPicker.selectRow(self.current, inComponent: 0, animated: true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.periods.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let display = Formatters.ViewDate.string(from: self.periods[row].start) + " - " + Formatters.ViewDateYear.string(from: self.periods[row].end)
        return display
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.okButton.isEnabled = true
    }

}
