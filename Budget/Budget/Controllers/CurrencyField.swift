//
//  CurrencyField.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/1/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

extension String {
    var digits: [UInt8] { return compactMap{ UInt8(String($0)) } }
}

extension Collection where Iterator.Element == UInt8 {
    var string: String { return map(String.init).joined() }
    var decimal: Decimal { return Decimal(string: string) ?? 0 }
}

class CurrencyField: UITextField {
    var string: String { return text ?? "" }
    var decimal: Decimal {
        return string.digits.decimal / Decimal(pow(10, Double(Formatters.Currency.maximumFractionDigits)))
    }
    var doubleValue: Double {
        return Double(truncating: decimal as NSNumber)
    }
    
    let maximum: Decimal = 999_999_999.99
    
    private var lastValue = ""
    
    override func willMove(toSuperview newSuperview: UIView?) {
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        keyboardType = .numberPad
        textAlignment = .right
        editingChanged()
    }
    
    override func deleteBackward() {
        guard decimal <= maximum else {
            text = lastValue
            return
        }
        text = string.digits.dropLast().string
        lastValue = Formatters.Currency.string(for: decimal) ?? ""
        text = lastValue
    }
    
    @objc func editingChanged() {
        guard decimal <= maximum else {
            text = lastValue
            return
        }
        
        lastValue = Formatters.Currency.string(for: decimal) ?? ""
        text = lastValue
    }
}
