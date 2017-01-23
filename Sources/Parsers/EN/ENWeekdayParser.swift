//
//  ENWeekdayParser.swift
//  SwiftyChrono
//
//  Created by Jerry Chen on 1/23/17.
//  Copyright © 2017 Potix. All rights reserved.
//

import Foundation

private let PATTERN = "(\\W|^)" +
    "(?:(?:\\,|\\(|\\（)\\s*)?" +
    "(?:on\\s*?)?" +
    "(?:(this|last|past|next)\\s*)?" +
    "(\(EN_WEEKDAY_OFFSET.keys.joined(separator: "|")))" +
    "(?:\\s*(?:\\,|\\)|\\）))?" +
    "(?:\\s*(this|last|past|next)\\s*week)?" +
    "(?=\\W|$)"

private let prefixGroup = 2
private let weekdayGroup = 3
private let postfixGroup = 4

private func updateParsedComponent(result: ParsedResult, ref: Date, offset: Int, modifier: String) -> ParsedResult {
    var result = result
    
    var startMoment = ref
    var startMomentFixed = false
    var refOffset = startMoment.day
    
    var day = startMoment.day
    
    if modifier == "last" || modifier == "past" {
        day = offset - 7
        startMomentFixed = true
    } else if modifier == "next" {
        day = offset + 7
        startMomentFixed = true
    } else if modifier == "this" {
        day = offset
    } else {
        if abs(offset - 7 - refOffset) < abs(offset - refOffset) {
            day = offset - 7
        } else if abs(offset + 7 - refOffset) < abs(offset - refOffset) {
            day = offset + 7
        } else {
            day = offset
        }
    }
    
    startMoment = Date(startMoment, byComponentUpdates: [(component: .day, value: day)])
    
    result.start.assign(.weekday, value: offset)
    if startMomentFixed {
        result.start.assign(.day, value: startMoment.day)
        result.start.assign(.month, value: startMoment.month)
        result.start.assign(.year, value: startMoment.year)
    } else {
        result.start.imply(.day, to: startMoment.day)
        result.start.imply(.month, to: startMoment.month)
        result.start.imply(.year, to: startMoment.year)
    }
    
    return result
}

public class ENWeekdayParser: Parser {
    override var pattern: String { return PATTERN }
    
    override public func extract(text: String, ref: Date, match: NSTextCheckingResult, opt: [OptionType: Int]) -> ParsedResult? {
        let (matchText, index) = matchTextAndIndex(from: text, andMatchResult: match)
        var result = ParsedResult(ref: ref, index: index, text: matchText)
        
        let dayOfWeek = match.string(from: text, atRangeIndex: weekdayGroup).lowercased()
        guard let offset = EN_WEEKDAY_OFFSET[dayOfWeek] else {
            return nil
        }
        
        let prefix: String? = match.isNotEmpty(atRangeIndex: prefixGroup) ? match.string(from: text, atRangeIndex: prefixGroup) : nil
        let postfix: String? = match.isNotEmpty(atRangeIndex: postfixGroup) ? match.string(from: text, atRangeIndex: postfixGroup) : nil
        let norm = (prefix ?? postfix ?? "").lowercased()
        
        result = updateParsedComponent(result: result, ref: ref, offset: offset, modifier: norm)
        result.tags[.enWeekdayParser] = true
        return result
    }
}