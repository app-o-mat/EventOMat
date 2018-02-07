//
//  Schedule.swift
//  EventOMat
//
//  Created by Louis Franco on 2/20/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import Foundation
import UIKit

enum Session: String {
    case beginner
    case intermediate
    case advanced
    case agile
    case `break`
    case drupal
    case panel
    case coaching
    case noncoding

    func color() -> UIColor {
        switch self {
        case .beginner:
            return #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
        case .advanced:
            return #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        case .intermediate:
            return #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        case .panel:
            return #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1)
        case .agile:
            return #colorLiteral(red: 0.4750122428, green: 0.01646117866, blue: 0, alpha: 1)
        case .`break`:
            return #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        case .coaching:
            return #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1)
        case .drupal:
            return #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        case .noncoding:
            return #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1)
        }
    }
}

struct ScheduleItem {
    let session: String
    let room: String
    let startTime: Int
    let type: Session
    let day: String
    let sessionText: String
}

class Schedule {

    static let sharedInstance = Schedule()

    let items: [String: [Int: [ScheduleItem]]]

    init() {
        items = Schedule.load()
    }

    class func items(forDay day: String, fromItems items: [ScheduleItem]) -> [Int: [ScheduleItem]] {
        return items
            .filter({ $0.day == day})
            .reduce([Int: [ScheduleItem]]()) { (groups, item) in
                var result = groups
                if let _ = result[item.startTime] {
                    result[item.startTime]?.append(item)
                } else {
                    result[item.startTime] = [item]
                }
                return result
            }
    }

    class func makeItemFromJSONObject(obj: Dictionary<String, Any>, for day: String) -> ScheduleItem? {
        guard let session = obj["name"] as? String,
            let room = obj["room"] as? String,
            let startTimeString = (obj["start"] as? String)?.split(separator: ":")[0],
            let startTime = Int(startTimeString),
            let typeString = (obj["type"] as? String)?.lowercased(),
            let sessionText = obj["description"] as? String,
            let type = Session(rawValue: typeString) else {
                return nil
        }
        return ScheduleItem(session: session, room: room, startTime: startTime, type: type, day: day, sessionText: sessionText)
    }

    class func load() -> [String: [Int: [ScheduleItem]]] {
        if let path = Bundle.main.path(forResource: "schedule", ofType: "json"),
            let scheduleData = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let json = try? JSONSerialization.jsonObject(with: scheduleData, options: []),
            let scheduleObject = json as? Dictionary<String, Array<Dictionary<String, Any>>> {

            var schedule = [String: [Int: [ScheduleItem]]]()

            let sat = scheduleObject["Saturday"]?.flatMap { obj in
                return makeItemFromJSONObject(obj: obj, for: "sat")
            } ?? [ScheduleItem]()
            schedule["sat"] = items(forDay: "sat", fromItems: sat)

            let sun = scheduleObject["Sunday"]?.flatMap { obj in
                return makeItemFromJSONObject(obj: obj, for: "sun")
                } ?? [ScheduleItem]()
            schedule["sun"] = items(forDay: "sun", fromItems: sun)

            return schedule
        }
        return [String: [Int: [ScheduleItem]]]()
    }

    class func loadPlist() -> [String: [Int: [ScheduleItem]]] {
        if let path = Bundle.main.path(forResource: "schedule", ofType: "plist"),
           let schedulePlist = NSDictionary(contentsOfFile: path) as? [String: Any],
           let schedule = schedulePlist["schedule"] as? [[String: Any]] {

            let all = schedule.flatMap{ (d: [String: Any]) -> ScheduleItem? in
                guard
                    let session = d["session"] as? String,
                    let room = d["room"] as? String,
                    let startTime = d["startTime"] as? Int,
                    let typeString = d["type"] as? String,
                    let day = d["day"] as? String,
                    let sessionText = d["sessiontext"] as? String,
                    let type = Session(rawValue: typeString) else {
                        return nil
                }
                return ScheduleItem(session: session, room: room, startTime: startTime, type: type, day: day, sessionText: sessionText)
            }

            var schedule = [String: [Int: [ScheduleItem]]]()
            schedule["sat"] = items(forDay: "sat", fromItems: all)
            schedule["sun"] = items(forDay: "sun", fromItems: all)
            return schedule
        }
        return [String: [Int: [ScheduleItem]]]()
    }

    func shouldInclude(item: ScheduleItem, withSearchTerm searchTerm: String) -> Bool {
        let terms = searchTerm.lowercased().split(separator: " ")
        for term in terms {
            if !item.session.lowercased().contains(String(term)) &&
                !item.room.contains(String(term)) &&
                !item.type.rawValue.contains(String(term)) {
                return false
            }
        }
        return true
    }

    func itemsGroupedByTimeFiltered(byDay day: String, searchTerm: String? = nil) -> [[ScheduleItem]] {
        let dayItems = self.items[day] ?? [:];


        var groupedItems = [[ScheduleItem]]()
        for time in dayItems.keys.sorted(by: { (a: Int, b: Int) -> Bool in
            // This treats the time as a clock from 9am - 6pm (e.g. (9+3)%12 is 0, so first in sort)
            return ((a + 3) % 12) < ((b + 3) % 12)
        }) {
            let filteredItems: [ScheduleItem]?
            if let searchTerm = searchTerm, searchTerm != "" {
                filteredItems = dayItems[time]?.filter({ item -> Bool in
                    return shouldInclude(item: item, withSearchTerm: searchTerm)
                })
            } else {
                filteredItems = dayItems[time]
            }
            groupedItems.append(filteredItems ?? [])
        }
        return groupedItems
    }

    class func sessionText(for item: ScheduleItem) -> String {
        return item.sessionText
    }

}
