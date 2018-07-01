//
//  Records.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

enum RecordsEvents: Int {
    case childAdded,
    childAddedInPeriod,
    childAddedBeforePeriod,
    childChanged,
    childChangedInPeriod,
    beforeChildRemoved,
    childRemoved,
    childRemovedInPeriod,
    childRemovedBeforePeriod,
    childRemovedAfterPeriod,
    childSaved,
    periodLoaded
}

private func emptyString(_: String) {}

class Records<T: BudgetRecord> : ObservableWithData<RecordsEvents, T> {
    let ref: DatabaseReference
    
    init(reference: DatabaseReference) {
        self.ref = reference
        super.init()
        
        self.ref.observe(.childAdded, with: self.childAddedHandler)
        self.ref.observe(.childChanged, with: self.childChangedHandler)
        self.ref.observe(.childRemoved, with: self.childRemovedHandler)
    }
    
    private func childAddedHandler(snapshot: DataSnapshot) {
        if let added = T(snapshot) {
            self.onChildAdded(added)
        }
    }
    
    private func childChangedHandler(snapshot: DataSnapshot) {
        if let changed = T(snapshot) {
            self.onChildChanged(changed)
        }
    }
    
    private func childRemovedHandler(snapshot: DataSnapshot) {
        if let removed = T(snapshot) {
            self.onChildRemoved(removed)
        }
    }
    
    
    internal func onChildAdded(_ record: T) {
        self.emit(.childAdded, Historical(record))
    }
    
    internal func onChildChanged(_ record: T) {
        self.emit(.childChanged, Historical(record))
    }
    
    internal func onChildRemoved(_ record: T) {
        self.emit(.childRemoved, Historical(record))
    }
    
    internal func onBeforeChildRemoved(_ record: T) {
        self.emit(.beforeChildRemoved, Historical(record))
    }
    
    internal func onChildSaved(_ record: T, _ original: T?) {
        self.emit(.childSaved, Historical(record, original))
    }
    
    func loadRecords(completion:@escaping ([String:T]) -> Void) {
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            var result: [String:T] = [:]
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let childItem = T.init(snapshot) {
                    result[snapshot.key] = childItem
                }
            }
            completion(result)
        })
    }
    
    func loadRecordsByChild(child: String, startAt: Any?, endAt: Any?, completion:@escaping ([String:T]) -> Void) {
        var cRef = self.ref.queryOrdered(byChild: child)
        if startAt != nil {
            cRef = cRef.queryStarting(atValue: startAt)
        }
        if endAt != nil {
            cRef = cRef.queryEnding(atValue: endAt)
        }
        
        
        cRef.observeSingleEvent(of: .value, with: { snapshot in
            var result: [String:T] = [:]
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                    let childItem = T(snapshot) {
                    result[snapshot.key] = childItem
                }
            }
            completion(result)
        })
    }
    
    func save(record: T, completion:@escaping ((String) -> Void) = emptyString) {
        let saveData = record.asObject()
        if record.ref != nil {
            // updating an existing record
            record.ref!.observeSingleEvent(of: .value, with: { snapshot in
                let original = T(snapshot)
                record.ref!.setValue(saveData)
                
                self.onChildSaved(record, original)
                
                completion(record.id!)
            })
        } else {
            // creating a new record
            record.ref = self.ref.childByAutoId()
            record.id = record.ref!.key
            record.ref!.setValue(saveData)
            
            self.onChildSaved(record, nil)
            
            completion(record.id!)
        }
    }
    
    func load(key: String, completion:@escaping (T) -> Void) {
        self.ref.child(key).observeSingleEvent(of: .value) { snapshot in
            guard
                let record = T(snapshot)
                else { return }
            completion(record)
        }
    }
    
    func remove(record: T, completion:@escaping ((String) -> Void) = emptyString) {
        self.onBeforeChildRemoved(record)
        guard
            record.ref != nil
            else { return }
        record.ref!.removeValue() { error, reference in
            completion(record.id!)
        }
    }
}
