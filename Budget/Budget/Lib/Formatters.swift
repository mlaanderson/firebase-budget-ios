//
//  Formatters.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/30/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

class Formatters {
    private static var saveDateFormatter: DateFormatter?
    private static var viewDateFormatter: DateFormatter?
    private static var viewDateYearFormatter: DateFormatter?
    private static var editDateFormatter: DateFormatter?
    private static var currencyFormatter: NumberFormatter?
    private static var doubleFormatter: NumberFormatter?
    
    static var SaveDate : DateFormatter {
        get {
            if (saveDateFormatter == nil) {
                saveDateFormatter = DateFormatter()
                saveDateFormatter?.dateFormat = "yyyy-MM-dd"
            }
            return saveDateFormatter!
        }
    }
    
    static var ViewDate : DateFormatter {
        get {
            if (viewDateFormatter == nil) {
                viewDateFormatter = DateFormatter()
                viewDateFormatter?.dateFormat = "MMM d"
            }
            return viewDateFormatter!
        }
    }
    
    static var ViewDateYear : DateFormatter {
        get {
            if (viewDateYearFormatter == nil) {
                viewDateYearFormatter = DateFormatter()
                viewDateYearFormatter?.dateFormat = "MMM d, yyyy"
            }
            return viewDateYearFormatter!
        }
    }

    static var EditDate : DateFormatter {
        get {
            if (editDateFormatter == nil) {
                editDateFormatter = DateFormatter()
                editDateFormatter?.dateFormat = "MMM d"
            }
            return editDateFormatter!
        }
    }
    
    static var Currency : NumberFormatter {
        get {
            if currencyFormatter == nil {
                currencyFormatter = NumberFormatter()
                currencyFormatter?.numberStyle = .currencyAccounting
                currencyFormatter?.allowsFloats = true
            }
            return currencyFormatter!
        }
    }
    
    static var NumberEdit : NumberFormatter {
        get {
            if doubleFormatter == nil {
                doubleFormatter = NumberFormatter()
                doubleFormatter?.numberStyle = .decimal
                doubleFormatter?.allowsFloats = true
                doubleFormatter?.maximumFractionDigits = 2
            }
            return currencyFormatter!
        }
    }
}
