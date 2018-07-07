//
//  DateExt.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/10/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

class Timespan {
    static let re_phrase = Regex(pattern: "(?<quantity>\\d+(?:\\.\\d+)?)\\s*(?<units>year|yr|month|week|wk|day|dy|hour|hr|min|minute|second|sec)s?", options: .caseInsensitive)
    static let re_time = Regex(pattern: "^(?<hours>\\d{1,2}):(?<minutes>\\d{2}):(?<seconds>\\d{2}(?:\\.\\d+)?)$", options: .caseInsensitive)
    static let re_month_days = Regex(pattern: "(?<first>\\d+)(?:st|nd|rd|th)?\\s+(?:(?:and|&)\\s+)?(?<second>\\d+)(?:st|nd|rd|th)?", options: .caseInsensitive)
    
    var seconds: Double
    var months: Int
    var years: Int
    var days: [Int]
    
    init() {
        self.seconds = 0
        self.months = 0
        self.years = 0
        self.days = []
    }
    
    init(years: Int, months: Int, seconds: Double, days: [Int]) {
        self.years = years
        self.months = months
        self.seconds = seconds
        self.days = days
    }
    
    static func parse(value: String) -> Timespan? {
        var months = 0
        var years = 0
        var sum = 0.0
        var days: [Int] = []
        
        if re_month_days.isMatch(value) {
            // this is a month days match
            let groups = re_month_days.matches(value)[0].groups
            guard
                let first = Int(groups["first"].value),
                let second = Int(groups["second"].value)
                else { return nil }
            
            days.append(first)
            days.append(second)
            return Timespan(years: years, months: months, seconds: sum, days: days)
        }
        
        if re_time.isMatch(value) {
            // this is a time type
            let groups = re_time.matches(value)[0].groups
            guard
                let hours = Int(groups["hours"].value),
                let minutes = Int(groups["minutes"].value),
                let seconds = Double(groups["seconds"].value)
                else { return nil }
            
            sum = Double(hours * 3600) + Double(minutes * 60) + seconds
            return Timespan(years: years, months: months, seconds: sum, days: days)
        }
        
        let phrases = re_phrase.matches(value)
        
        for phrase in phrases {
            guard
                let quantity = Double(phrase.groups["quantity"].value)
                else { continue }
            let units = phrase.groups["units"].value.lowercased()
            
            switch units {
            case "year", "yr":
                years += Int(quantity)
                break
            case "month":
                months += Int(quantity)
                break
            case "week", "wk":
                sum += quantity * 7 * 24 * 3600
                break
            case "day", "dy":
                sum += quantity * 24 * 3600
                break
            case "hour", "hr":
                sum += quantity * 3600
                break
            case "minute", "min":
                sum += quantity * 60
                break
            default:
                sum += quantity
                break;
            }
        }
        
        return Timespan(years: years, months: months, seconds: sum, days: days)
    }
}

extension String {
    init(_ ts: Timespan) {
        var result = ""
        
        if (ts.days.count == 2) {
            result += String(ts.days[0])
            
            if (ts.days[0] % 10) == 1 {
                result += "st"
            } else if (ts.days[0] % 10) == 2 {
                result += "nd"
            } else if (ts.days[0] % 10) == 3 {
                result += "rd"
            } else {
                result += "th"
            }
            
            result += " and " + String(ts.days[1])
            
            if (ts.days[1] % 10) == 1 {
                result += "st"
            } else if (ts.days[1] % 10) == 2 {
                result += "nd"
            } else if (ts.days[1] % 10) == 3 {
                result += "rd"
            } else {
                result += "th"
            }
        } else {
            let weeks = Int(floor(ts.seconds / 3600.0 / 24.0 / 7.0))
            var time = ts.seconds - Double(weeks) * 3600.0 * 24.0 * 7.0
            
            let days = Int(floor(time / 3600.0 / 24.0))
            time = time - Double(days) * 3600.0 * 24.0
            
            let hours = Int(floor(time / 3600.0))
            time = time - Double(hours) * 3600.0
            
            let minutes = Int(floor(time / 60.0))
            time = time - Double(minutes) * 60.0
            
            func format(_ val: Int, _ suffix: String) {
                if (val != 0) {
                    result += (result == "" ? "" : " ") + String(val) + " " + suffix
                }
            }
            
            
            format(ts.years, "years")
            format(ts.months, "months")
            format(weeks, "weeks")
            format(days, "days")
            if (hours != 0) || (minutes != 0) || (abs(time) >= 0.001) {
                
                result += (result == "" ? "" : " ") + String(format: "%d:%02d:%02f", hours, minutes, time)
            }
        }
        
        
        self = result
    }
}

extension Date {
   
    func toFbString() -> String {
        return Formatters.SaveDate.string(from: self)
    }
    
    static func parseFb(value: String) -> Date? {
        return Formatters.SaveDate.date(from: value)
    }
    
    private func getParts() -> DateComponents {
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
    }
    
    func getYear() -> Int {
        return self.getParts().year!
    }
    
    func getMonth() -> Int {
        return self.getParts().month!
    }
    
    func getDay() -> Int {
        return self.getParts().day!
    }
    
    func subtract(timespan: Timespan) -> Date {
        var parts = self.getParts()
        parts.year! -= timespan.years
        parts.month! -= timespan.months
        
        if timespan.days.count > 0 {
            var result = self - "1 day"
            var match = false
            
            repeat {
                if timespan.days.index(of: result.getDay()) != nil {
                    match = true
                } else if result.getDay() == result.daysInMonth() && timespan.days.contains { el in
                    return el > result.getDay()
                    } {
                    match = true
                } else {
                    result = result - "1 day"
                }
            } while match == false
            
            return result
        }
        
        while parts.month! > 12 {
            parts.year! += 1
            parts.month! -= 12
        }
        
        while parts.month! < 0 {
            parts.year! -= 1
            parts.month! += 12
        }
        
        let result = Calendar.current.date(from: parts)
        return result! - timespan.seconds
    }
    
    func subtract(timespan: String) -> Date {
        return self.subtract(timespan: Timespan.parse(value: timespan) ?? Timespan())
    }
    
    func add(timespan: Timespan) -> Date {
        var parts = self.getParts()
        parts.year! += timespan.years
        parts.month! += timespan.months
        
        if timespan.days.count > 0 {
            var result = self + "1 day"
            var match = false
            
            repeat {
                if timespan.days.index(of: result.getDay()) != nil {
                    match = true
                } else if result.getDay() == result.daysInMonth() && timespan.days.contains { el in
                    return el > result.getDay()
                    } {
                    match = true
                } else {
                    result = result + "1 day"
                }
            } while match == false
            
            return result
        }
        
        while parts.month! > 12 {
            parts.year! += 1
            parts.month! -= 12
        }
        
        while parts.month! < 0 {
            parts.year! -= 1
            parts.month! += 12
        }
        
        let result = Calendar.current.date(from: parts)
        return result! + timespan.seconds
    }
    
    func add(timespan: String) -> Date {
        return self.add(timespan: Timespan.parse(value: timespan) ?? Timespan())
    }
    
    
    func periodCalc(start: String, length: String) -> Date {
        var result = Date.parseFb(value: start)!
        while (result + length) < self {
            result = result + length
        }
        return result
    }
    
    func daysInMonth() -> Int {
        let month = self.getMonth()
        let year = self.getYear()
        if month == 2 {
            if year % 400 == 0 {
                return 29
            }
            if year % 100 == 0 {
                return 28
            }
            if year % 4 == 0 {
                return 29
            }
            return 28
        }
        if month < 7 && (month % 2) == 1 {
            return 31
        }
        if month > 6 && (month % 2) == 2 {
            return 31
        }
        return 30
        
    }
    
    static func +(left: Date, right: Timespan) -> Date {
        return left.add(timespan: right)
    }
    
    static func +(left: Date, right: String) -> Date {
        return left.add(timespan: right)
    }
    
    static func +(left: Timespan, right: Date) -> Date {
        return right.add(timespan: left)
    }
    
    static func +(left: String, right: Date) -> Date {
        return right.add(timespan: left)
    }
    
    static func -(left: Date, right: String) -> Date {
        return left.subtract(timespan: right)
    }
    
    static func -(left: Date, right: Timespan) -> Date {
        return left.subtract(timespan: right)
    }
    
    static func today() -> Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    static func periodCalc(start: String, length: String) -> Date {
        return Date.today().periodCalc(start: start, length: length)
    }
    
    static func range(start: Date, end: Date, period: Timespan) -> [Date] {
        var date = start
        var result: [Date] = []
        
        repeat {
            result.append(date)
            date = date + period
        } while date <= end + "1 day"
        
        return result
    }
    
    static func range(start: String, end: String, period: String) -> [Date] {
        return Date.range(start: Date.parseFb(value: start)!, end: Date.parseFb(value: end)!, period: Timespan.parse(value: period)!)
    }
    
    static func range(start: Date, end: Date, period: String) -> [Date] {
        return Date.range(start: start, end: end, period: Timespan.parse(value: period)!)
    }
}
