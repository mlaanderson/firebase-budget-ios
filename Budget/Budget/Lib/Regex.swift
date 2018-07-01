//
//  Regex.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

class Group {
    let _range: NSRange
    let _match: Match
    
    init(match: Match, range: NSRange) {
        self._match = match
        self._range = range
    }
    
    var range: Range<String.Index>? {
        get {
            return Range(self._range, in: self._match.input)
        }
    }
    
    var value: String {
        get {
            return String(self._match.input[self.range!])
        }
    }
}

class GroupCollection:Sequence {
    let match: Match
    
    init(match: Match) {
        self.match = match
    }
    
    public func makeIterator() -> GroupCollection.Iterator {
        return GroupCollection.Iterator(self)
    }
    
    var count: Int {
        get {
            return self.match.baseMatch.numberOfRanges
        }
    }
    
    subscript(index: Int) -> Group {
        get {
            return Group(match: self.match, range: self.match.baseMatch.range(at: index))
        }
    }
    
    subscript(index: String) -> Group {
        get {
            return Group(match: self.match, range: self.match.baseMatch.range(withName: index))
        }
    }
    
    class Iterator : IteratorProtocol {
        typealias Element = Group
        
        var collection: GroupCollection
        var pointer: Int
        
        init(_ collection: GroupCollection) {
            self.collection = collection
            self.pointer = 0
        }
        
        public func next() -> Element? {
            if pointer >= collection.count - 1 { return nil }
            let thisone = collection[pointer]
            pointer = pointer + 1
            return thisone
        }
    }
}


class Match {
    let baseMatch: NSTextCheckingResult
    let input: String
    
    init(input: String, nsMatch: NSTextCheckingResult) {
        self.baseMatch = nsMatch
        self.input = input
    }
    
    var value: String? {
        get {
            return String(self.input[Range(self.baseMatch.range, in: input)!])
        }
    }
    
    var groups: GroupCollection {
        get {
            return GroupCollection(match: self)
        }
    }
}


class Regex {
    let baseRegex: NSRegularExpression
    
    init(pattern: String, options: NSRegularExpression.Options) {
        self.baseRegex = try! NSRegularExpression(pattern: pattern, options: options)
    }
    
    func isMatch(_ input: String) -> Bool {
        return matches(input).count > 0
    }
    
    func matches(_ input: String) -> [Match] {
        return self.baseRegex.matches(in: input, options: [], range: NSMakeRange(0, input.count)).map({ Match(input: input, nsMatch: $0) })
    }
}
