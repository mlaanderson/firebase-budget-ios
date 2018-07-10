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
    private var earlierRecords: [String:Transaction] = [:]
    private var periodStart: String?
    private var periodEnd: String?
    var total: Double
    
    override init(reference: DatabaseReference) {
        total = 0
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
            total += record.amount
            
            self.records[record.id!] = record
            self.populateTransactionList()
            
            self.emit(.childAddedInPeriod, Historical(record))
        } else if record.date < self.periodStart! {
            total += record.amount
            
            self.emit(.childAddedBeforePeriod, Historical(record))
        }
        
        super.onChildAdded(record)
    }
    
    override func onChildChanged(_ record: Transaction) {
        guard
            self.periodStart != nil,
            self.periodEnd != nil
            else { return }
        
        var repopulate = false;

        if let removed = self.records.removeValue(forKey: record.id!) {
            total -= removed.amount
            repopulate = true
        }
        if let removed = self.earlierRecords.removeValue(forKey: record.id!) {
            total -= removed.amount
            repopulate = true
        }
        
        if self.inPeriod(record.date) {
            self.records[record.id!] = record
            total += record.amount
            self.populateTransactionList()
            repopulate = false
            
            self.emit(.childChangedInPeriod, Historical(record))
        }
        
        if repopulate {
            self.populateTransactionList()
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
            total -= record.amount
            self.emit(.childRemovedInPeriod, Historical(record))
        } else if record.date < self.periodStart! {
            total -= record.amount
            self.emit(.childRemovedBeforePeriod, Historical(record))
        }
        
        self.emit(.childRemoved, Historical(record))
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
        self.loadRecordsByChild(child: "date", startAt: nil, endAt: end) { records in
            self.records = [:]
            self.total = 0
            
            self.total = records.values.reduce(0.0) { result, tr in return tr.amount + result }
            self.records = records.filter { key, tr in
                return start <= tr.date && tr.date <= end
            }
            self.earlierRecords = records.filter { key, tr in
                return tr.date < start
            }
            
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

    func search(search: String, completion:@escaping (_ transactions: [Transaction]) -> Void) {
        let searcher = Regex(pattern: search, options: [.caseInsensitive])
        self.loadRecords { records in
            let result = records.values.filter({ searcher.isMatch($0.name) }).sorted { a, b in
                guard let aIdx = self.Categories.index(of: a.category)
                    else { return true }
                guard let bIdx = self.Categories.index(of: b.category)
                    else { return false }
                
                if aIdx == bIdx {
                    if a.date < b.date { return true }
                }
                
                return aIdx < bIdx
            }
            completion(result)
        }
    }
}
