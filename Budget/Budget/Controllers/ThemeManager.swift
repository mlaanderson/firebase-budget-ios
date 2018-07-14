//
//  ThemeManager.swift
//  Budget
//
//  Created by Mike Kari Anderson on 7/14/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import UIKit

enum Theme: String {
    case defaultTheme, purpleTheme, brownTheme
    
    var mainColor: UIColor {
        return UIColor(named: self.rawValue + "/mainColor")!
    }
    
    var barTintColor: UIColor {
        return UIColor(named: self.rawValue + "/barTintColor")!
    }
    
    var backgroundColor: UIColor {
        return UIColor(named: self.rawValue + "/backgroundColor")!
    }
    
    var secondaryColor: UIColor {
        return UIColor(named: self.rawValue + "/secondaryColor")!
    }
    
    var titleTextColor: UIColor {
        return UIColor(named: self.rawValue + "/titleTextColor")!
    }
    
    var subtitleTextColor: UIColor {
        return UIColor(named: self.rawValue + "/subtitleTextColor")!
    }
}

let SelectedThemeKey = "SelectedTheme"

class ThemeManager {
    static func currentTheme() -> Theme {
        if let storedTheme = (UserDefaults.standard.value(forKey: SelectedThemeKey) as AnyObject).stringValue {
            return Theme(rawValue: storedTheme)!
        }
        return .defaultTheme
    }
    
    static func applyTheme(theme: Theme) {
        // persist the theme
        UserDefaults.standard.setValue(theme.rawValue, forKey: SelectedThemeKey)
        UserDefaults.standard.synchronize()
        
        // apply the theme to the application
        let sharedApplication = UIApplication.shared
        sharedApplication.delegate?.window??.tintColor = theme.mainColor
        
        UINavigationBar.appearance().backgroundColor = theme.barTintColor
        
        UITabBar.appearance().backgroundColor = theme.barTintColor
    }
}
