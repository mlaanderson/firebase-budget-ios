//
//  BudgetData.swift
//  BudgetData
//
//  Created by Mike Kari Anderson on 6/24/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

enum BudgetEvents: Int {
    case configRead,
    ready,
    loadPeriod
}

class BudgetData : Observable<BudgetEvents, AnyObject> {
    private let root: DatabaseReference
    private var account: DatabaseReference?
    private var isReady: Bool = false
    var period: Period = Period(start: Date.today(), end: Date.today() + "2 weeks" - "1 day")
    
    var config: Configuration = Configuration(data: ["categories":[], "periods": ["start":"2016-06-24","length":"2 weeks"]] as AnyObject)!
    
    lazy var transactions: Transactions = {
        return Transactions(reference: account!.child("transactions"))
    }()
    
    lazy var recurrings: RecurringTransactions = {
        return RecurringTransactions(reference: account!.child("recurring"))
    }()
    
    var Ready : Bool { get { return self.isReady } }
    
    
    init(_ reference: DatabaseReference) {
        self.root = reference
        
        super.init()
        
        self.root.child("config").observeSingleEvent(of: .value) { snapshot in
            self.config = Configuration(snapshot)!
            
            // find the root account
            self.root.child("accounts").queryOrdered(byChild: "name").queryStarting(atValue: "Primary").queryEnding(atValue: "Primary").observeSingleEvent(of: .childAdded) { snapshot in
                self.account = snapshot.ref

                self.emit(.configRead)
            }
        }
    }
    
    var Categories : [String] {
        get {
            var used = self.transactions.Categories
            used.sort() { a, b in
                guard let aIdx = self.config.categories.index(of: a)
                    else { return true }
                guard let bIdx = self.config.categories.index(of: b)
                    else { return false }
                
                return aIdx < bIdx
            }
            return used
        }
    }
    
    var CanGoBack : Bool {
        get {
            return self.transactions.Start ?? "" > self.config.start
        }
    }
    
    func goBack() {
        if !self.CanGoBack { return }
        let date = self.period.start - self.config.length + "1 day"
        self.gotoDate(date)
    }
    
    func goForward() {
        let date = self.period.end + self.config.length - "1 day"
        self.gotoDate(date)
    }

    func gotoDate(_ date: Date) {
        self.period = self.config.calculatePeriod(date: date)

        self.transactions.loadPeriod(start: self.period.start.toFbString(), end: self.period.end.toFbString()) { transactions in
            
            if (self.isReady == false) {
                self.isReady = true;
                self.emit(.ready)
            }
            self.emit(.loadPeriod)
        }
    }
    
    func saveTransaction(_ transaction: Transaction)  {
        self.transactions.save(record: transaction) { id in
            // populate for undo/redo
        }
    }
    
    func removeTransaction(_ transaction: Transaction) {
        self.transactions.remove(record: transaction) { id in
            // populate for undo/redo
        }
    }
    
    func saveRecurring(_ transaction: RecurringTransaction) {
        self.recurrings.save(record: transaction) { id in
            var date = Date.periodCalc(start: self.config.start, length: self.config.length).toFbString()
            
            if date < self.period.start.toFbString() {
                date = self.period.start.toFbString()
            }
            
            self.transactions.getRecurring(id: id) { transactions in
                let toDelete = transactions.values.filter({ $0.date >= date && !$0.paid })
                for tr in toDelete {
                    self.transactions.remove(record: tr)
                }
            }
            
            for tDate in Date.range(start: date, end: transaction.end, period: transaction.period) {
                if (tDate >= self.period.start) {
                    var object = [AnyHashable:Any]()
                    object["amount"] = transaction.amount
                    object["cash"] = transaction.cash
                    object["category"] = transaction.category
                    object["date"] = tDate.toFbString()
                    object["name"] = transaction.name
                    object["note"] = transaction.note
                    object["recurring"] = id
                    object["transfer"] = transaction.transfer
                    if let newTransaction = Transaction(data: object as AnyObject) { self.transactions.save(record: newTransaction) }
                }
            }
        }
    }
    
    func removeRecurring(_ transaction: RecurringTransaction) {
        self.recurrings.save(record: transaction) { id in
            var date = Date.periodCalc(start: self.config.start, length: self.config.length).toFbString()
            
            if date < self.period.start.toFbString() {
                date = self.period.start.toFbString()
            }
            
            self.transactions.getRecurring(id: id) { transactions in
                let toDelete = transactions.values.filter({ $0.date >= date && !$0.paid })
                for tr in toDelete {
                    self.transactions.remove(record: tr)
                }
            }
        }
    }
}

