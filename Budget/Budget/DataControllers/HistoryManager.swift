//
//  HistoryManager.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/7/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

enum HistoryActions {
    case create, change, delete
}

enum HistoryTypes {
    case transaction, recurring
}

class HistoryItem {
    var action: HistoryActions
    var type: HistoryTypes
    var initial: BudgetRecord?
    var final: BudgetRecord
    
    init(action: HistoryActions, type: HistoryTypes, final: BudgetRecord, initial: BudgetRecord?) {
        self.action = action
        self.type = type
        self.final = final
        self.initial = initial
    }
}

class HistoryManager {
    static let maxItems = 100
    let budget: BudgetData
    var history = [HistoryItem]()
    var pointer = 0
    
    init(_ budget: BudgetData) {
        self.budget = budget
    }
    
    func undoItem() -> HistoryItem? {
        guard canUndo else { return nil }
        return history[pointer - 1]
    }
    
    func append(action: HistoryActions, final: BudgetRecord, initial: BudgetRecord?) {
        if final as? Transaction != nil {
            self.history.append(HistoryItem(action: action, type: .transaction, final: final, initial: initial))
        } else if final as? RecurringTransaction != nil {
            self.history.append(HistoryItem(action: action, type: .recurring, final: final, initial: initial))
        }
        
        while history.count > HistoryManager.maxItems {
            history.remove(at: 0)
        }

        pointer = history.count
    }
    
    func save(_ record: BudgetRecord, initial: BudgetRecord) {
        guard
        record.id != nil
            else { return }
        if let transaction = record as? Transaction {
            self.append(action: .change, final: transaction, initial: initial)
        }
        if let transaction = record as? RecurringTransaction {
            self.append(action: .change, final: transaction, initial: initial)
        }
    }
    
    func create(_ record: BudgetRecord) {
        guard
        record.id != nil
            else { return }
        self.append(action: .create, final: record, initial: nil)
    }
    
    func delete(_ record: BudgetRecord) {
        guard
        record.id != nil
            else { return }
        
        if let transaction = record as? Transaction {
            self.append(action: .delete, final: transaction, initial: nil)
        }
        if let transaction = record as? RecurringTransaction {
            // this should not happen
            self.append(action: .delete, final: transaction, initial: nil)
        }
    }
    
    var canUndo: Bool {
        get {
            return pointer > 0
        }
    }
    
    private func undoChangeTransaction(_ item: HistoryItem) {
        guard
        let initial = item.initial as? Transaction
        else { return }
        
        budget.transactions.save(record: initial)
    }
    
    private func undoCreateTransaction(_ item: HistoryItem) {
        guard
        item.final.id != nil,
        let transaction = item.final as? Transaction
            else { return }
        
        budget.transactions.remove(record: transaction)
    }
    
    private func undoDeleteTransaction(_ item: HistoryItem) {
        guard
        let transaction = item.final as? Transaction
            else { return }
        
        budget.transactions.save(record: transaction)
    }
    
    private func undoChangeRecurring(_ item: HistoryItem) {
        guard
            let initial = item.initial as? RecurringTransaction
            else { return }
        
        budget.recurrings.save(record: initial)
    }
    
    private func undoCreateRecurring(_ item: HistoryItem) {
        guard
        let id = item.final.id,
        let transaction = item.final as? RecurringTransaction,
        let active = transaction.active
            else { return }
        
        // duplicate the transaction into initial with the delete value set instead of active
        budget.recurrings.load(key: id) { initial in
            initial.delete = active
            item.initial = initial

            // modify the action since recurrings are always changes
            item.action = .change

            self.undoChangeRecurring(item)
        }
    }
    
    private func undoDeleteRecurring(_ item: HistoryItem) {
        // this shouldn't happen, but...
        guard
        let id = item.final.id,
        let transaction = item.final as? RecurringTransaction,
        let delete = transaction.delete
            else { return }

        budget.recurrings.load(key: id) { initial in
            initial.active = delete
            item.initial = initial
            
            item.action = .change
            self.undoChangeRecurring(item)
        }
        
    }

    func undo() {
        guard canUndo else { return }
        
        pointer -= 1
        
        let item = self.history[pointer]
        
        switch item.action {
        case .change:
            if item.type == .transaction { undoChangeTransaction(item) }
            if item.type == .recurring { undoChangeRecurring(item) }
            break
        case .create:
            if item.type == .transaction { undoCreateTransaction(item) }
            if item.type == .recurring { undoCreateRecurring(item) }
            break
        case .delete:
            if item.type == .transaction { undoDeleteTransaction(item) }
            if item.type == .recurring { undoDeleteRecurring(item) }
            break
        }
    }
    
    var canRedo: Bool {
        get { return pointer < history.count && pointer >= 0 }
    }
    
    private func redoChangeTransaction(_ item: HistoryItem) {
        guard
            let final = item.final as? Transaction
            else { return }
        
        budget.transactions.save(record: final)
    }
    
    private func redoCreateTransaction(_ item: HistoryItem) {
        guard
            item.final.id != nil,
            let transaction = item.final as? Transaction
            else { return }
        
        budget.transactions.save(record: transaction)
    }
    
    private func redoDeleteTransaction(_ item: HistoryItem) {
        guard
            let transaction = item.final as? Transaction
            else { return }
        
        budget.transactions.remove(record: transaction)
    }
    
    private func redoChangeRecurring(_ item: HistoryItem) {
        guard
            let final = item.final as? RecurringTransaction
            else { return }
        
        budget.recurrings.save(record: final)
    }
    
    func redo() {
        guard canRedo else { return }
        
        let item = self.history[pointer]
        pointer += 1
        
        switch item.type {
        case .transaction:
            switch item.action {
            case .change: redoChangeTransaction(item)
                break
            case .create: redoCreateTransaction(item)
                break
            case .delete: redoDeleteTransaction(item)
                break
            }
            
            break
        case .recurring:
            // undos alter the type into change, so all redos of recurring are change
            redoChangeRecurring(item)
            break
        }
        
    }
}
