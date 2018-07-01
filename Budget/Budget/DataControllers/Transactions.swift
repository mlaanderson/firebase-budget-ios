//
//  Transactions.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//


import Firebase

class Transactions : Records<Transaction> {
    private var records: [String:Transaction] = [:]
    private var recordList: [Transaction] = []
    private var periodStart: String?
    private var periodEnd: String?
    
    override init(reference: DatabaseReference) {
        super.init(reference: reference)
    }
    
    private func inPeriod(_ date: String) -> Bool {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return false }
        return (self.periodStart! <= date) && (date <= self.periodEnd!)
    }
    
    // don't need to sort since the view does that for us
    private func populateTransactionList() {
        self.recordList = Array(self.records.values)
    }
    
    override func onChildAdded(_ record: Transaction) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return }

        if self.inPeriod(record.date) {
            self.records[record.id!] = record
            self.populateTransactionList()
            
            self.emit(.childAddedInPeriod, Historical(record))
        } else if record.date < self.periodStart! {
            self.emit(.childAddedBeforePeriod, Historical(record))
        }
        
        super.onChildAdded(record)
    }
    
    override func onChildChanged(_ record: Transaction) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return }

        if self.inPeriod(record.date) {
            self.records[record.id!] = record
            self.populateTransactionList()
            
            self.emit(.childChangedInPeriod, Historical(record))
        } else {
            if self.records.removeValue(forKey: record.id!) != nil {
                self.populateTransactionList()
            }
        }
        
        self.emit(.childChanged, Historical(record))
    }
    
    override func onChildRemoved(_ record: Transaction) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return }

        if self.records.removeValue(forKey: record.id!) != nil {
            self.populateTransactionList();
        }
        
        if self.inPeriod(record.date) {
            self.emit(.childRemovedInPeriod, Historical(record))
        } else if record.date < self.periodStart! {
            self.emit(.childRemovedBeforePeriod, Historical(record))
        }
        
        self.emit(.childRemoved, Historical(record))
    }
    
    override func onChildSaved(_ current: Transaction, _ original: Transaction?) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return }

        if self.inPeriod(current.id!) {
            self.records[current.id!] = current
        } else {
            self.records.removeValue(forKey: current.id!)
        }
    }
    
    public var Records: [String:Transaction] {
        get { return self.records }
    }
    
    public var List: [Transaction] {
        get { return self.recordList }
    }
    
    public var Categories: [String] {
        get {
            return Array(Set(self.List.map({ $0.category })))
        }
    }
    
    public var Start: String? {
        get { return self.periodStart }
    }
    
    public var End: String? {
        get { return self.periodEnd }
    }
    
    public var Cash: Budget.Cash {
        get {
            var result = Budget.Cash()
            for record in (self.recordList.filter { $0.cash && !$0.paid  && !$0.deposit }) {
                result = result + Budget.Cash(record.amount)
            }
            return result
        }
    }
    
    
    public var Transfer: Double {
        get {
            var result = 0.0
            for record in (self.recordList.filter { $0.transfer && !$0.paid }) {
                result += record.amount
            }
            return result
        }
    }
    
    public func getSame(record: Transaction, completion:@escaping ([Transaction]) -> Void) {
        self.loadRecordsByChild(child: "name", startAt: record.name, endAt: record.name) { records in
            let result = records.values.filter { $0.category == record.category }
            completion(result)
        }
    }
    
    public func loadPeriod(start: String, end: String, completion:@escaping ([String:Transaction]) -> Void) {
        self.loadRecordsByChild(child: "date", startAt: start, endAt: end) { records in
            self.records = records
            self.populateTransactionList()
            self.periodStart = start
            self.periodEnd = end
            
            completion(self.records)
            self.emit(.periodLoaded)
        }
    }
    
    public func getRecurring(id: String, completion:@escaping ([String:Transaction]) -> Void) {
        self.loadRecordsByChild(child: "recurring", startAt: id, endAt: id, completion: completion)
    }
    
    public func getTotal(completion:@escaping (Double) -> Void) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else {
                completion(0.0)
                return
            }
        
        self.loadRecordsByChild(child: "date", startAt: nil, endAt: self.periodEnd) { records in
            let total = records.values.map({ $0.amount }).reduce(0, +)
            completion(total)
        }
    }
    
    // TODO SEARCH
}
