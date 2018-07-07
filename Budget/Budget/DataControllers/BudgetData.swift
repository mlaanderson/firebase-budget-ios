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
    loadPeriod,
    historyChanged
}

class BudgetData : Observable<BudgetEvents, AnyObject> {
    private let root: DatabaseReference
    private var account: DatabaseReference?
    private var isReady: Bool = false
    private lazy var history: HistoryManager = { return HistoryManager(self) }()
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
        if let id = transaction.id {
            self.transactions.load(key: id) { initial in
                self.transactions.save(record: transaction) { _ in
                    self.history.save(transaction, initial: initial)
                    self.emit(.historyChanged)
                }
            }
        } else {
            self.transactions.save(record: transaction) { id in
                transaction.id = id
                self.history.create(transaction)
                self.emit(.historyChanged)
            }
        }
    }
    
    func removeTransaction(_ transaction: Transaction) {
        self.transactions.remove(record: transaction) { id in
            // populate for undo/redo
            self.history.delete(transaction)
            self.emit(.historyChanged)
        }
    }
    
    func saveRecurring(_ transaction: RecurringTransaction) {
        var date = Date.periodCalc(start: self.config.start, length: self.config.length).toFbString()
        
        if date < self.period.start.toFbString() {
            date = self.period.start.toFbString()
        }
        
        transaction.active = date
        transaction.delete = nil
        
        if transaction.id != nil {
            self.recurrings.load(key: transaction.id!) { initial in
                self.recurrings.save(record: transaction) { id in
                    // leave for undo
                    initial.delete = date
                    initial.active = nil
                    self.history.save(transaction, initial: initial)
                    self.emit(.historyChanged)
                }
            }
        } else {
            self.recurrings.save(record: transaction) { id in
                // leave for undo
                transaction.id = id
                self.history.create(transaction)
                self.emit(.historyChanged)
            }
        }
    }
    
    func removeRecurring(_ transaction: RecurringTransaction) {
        guard transaction.id != nil else { return }
        var date = Date.periodCalc(start: self.config.start, length: self.config.length).toFbString()
        
        if date < self.period.start.toFbString() {
            date = self.period.start.toFbString()
        }
        transaction.delete = date
        transaction.active = nil
        self.recurrings.load(key: transaction.id!) { initial in
            self.recurrings.save(record: transaction) { id in
                // leave for undo
                initial.active = date
                initial.delete = nil
                self.history.save(transaction, initial: initial)
                self.emit(.historyChanged)
            }
        }
    }
    
    var canUndo : Bool {
        get { return self.history.canUndo }
    }
    
    var canRedo : Bool {
        get { return self.history.canRedo }
    }
    
    func undo() {
        guard canUndo else { return }
        self.history.undo()
        self.emit(.historyChanged)
    }
    
    func redo() {
        guard canRedo else { return }
        self.history.redo()
        self.emit(.historyChanged)
    }
}

