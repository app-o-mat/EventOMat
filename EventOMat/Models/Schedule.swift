//
//  Schedule.swift
//  EventOMat
//
//  Created by Louis Franco on 2/20/17.
//  Copyright © 2017 Lou Franco. All rights reserved.
//

import Foundation
import UIKit

let colors = [
    #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1),
    #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1),
    #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1),
    #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
    #colorLiteral(red: 0.5568627715, green: 0.3529411852, blue: 0.9686274529, alpha: 1),
    #colorLiteral(red: 0.4750122428, green: 0.01646117866, blue: 0, alpha: 1),
    #colorLiteral(red: 0.9994240403, green: 0.9855536819, blue: 0, alpha: 1),
    #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
    #colorLiteral(red: 0.9372549057, green: 0.3490196168, blue: 0.1921568662, alpha: 1),
    #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1),
    #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1),
    #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1),
    #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1),
]

var types = Set<String>()

func sessionColor(type: String) -> UIColor {
    let index = types.sorted().firstIndex(of: type) ?? 0
    return colors[index % colors.count]
}

struct ScheduleItem {
    let session: String
    let room: String
    let startTime: Double
    let type: String
    let day: String
    let sessionText: String
    let speaker: String
}

class Schedule {

    static let sharedInstance = Schedule()

    var session: URLSession? = nil
    var items: [String: [Double: [ScheduleItem]]]?

    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        session = URLSession(configuration: config)
        Schedule.load(session: session, completion: { (items) in
            self.items = items
        })
    }

    class func getItems(forDay day: String, fromItems items: [ScheduleItem]) -> [Double: [ScheduleItem]] {
        return items
            .filter({ $0.day == day})
            .reduce([Double: [ScheduleItem]]()) { (groups, item) in
                var result = groups
                if let _ = result[item.startTime] {
                    result[item.startTime]?.append(item)
                } else {
                    result[item.startTime] = [item]
                }
                return result
            }
    }

    class func formatTime(time: Double) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: time))
    }

    class func parseTime(timeString: String) -> Double? {
        let timeParts = timeString.split(separator: ":")
        guard timeParts.count == 2 else {
            return nil
        }
        guard let hour = Double(timeParts[0]) else {
            return nil
        }
        let minuteAMPM = String(timeParts[1])
        let minuteIndex = minuteAMPM.index(minuteAMPM.startIndex, offsetBy: 2)
        guard let minute = Double(minuteAMPM[..<minuteIndex]) else {
            return nil
        }
        let ampm = minuteAMPM[minuteIndex...].trimmingCharacters(in: .whitespaces).lowercased()

        return (hour + (ampm=="am" || hour >= 12 ? 0 : 12)) * (60*60) + (minute * 60)
    }

    class func makeItemFromJSONObject(obj: [String: Any], for day: String) -> ScheduleItem? {
        guard let session = obj["name"] as? String,
            let room = obj["room"] as? String,
            let startString = obj["start"] as? String,
            let startTime = parseTime(timeString: startString),
            let type = (obj["type"] as? String)?.lowercased(),
            let sessionText = obj["description"] as? String else {
                return nil
        }
        types.insert(type)
        return ScheduleItem(session: session, room: room, startTime: startTime, type: type, day: day, sessionText: sessionText, speaker:  obj["speaker"] as? String ?? "")
    }

    class func documentsFolder() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    class func scheduleFilePath() -> URL {
        return documentsFolder().appendingPathComponent("schedule.json")
    }

    class func cacheSchedule(data: Data) {
        try? data.write(to: scheduleFilePath())
    }

    class func getCachedSchedule() -> Data? {
        return try? Data(contentsOf: scheduleFilePath())
    }

    struct CellCoord: Hashable {
        let row: Int
        let col: Int
    }

    class func parse(json: Any) -> [String: [[String: Any]]]? {
        // .feed.entry[0]."gs$cell"
        guard
            let jsonDict = json as? [String: Any],
            let feed = jsonDict["feed"] as? [String: Any],
            let entries = feed["entry"] as? [Any]

        else { return nil }

        let cells = entries.reduce([CellCoord: [String: Any]]()) { (r, e) -> [CellCoord: [String: Any]] in
            guard
                let eDict = e as? [String: Any],
                let cell = eDict["gs$cell"] as? [String: Any],
                let rowString = cell["row"] as? String,
                let row = Int(rowString),
                let colString = cell["col"] as? String,
                let col = Int(colString)
            else { return r }

            return r.merging([CellCoord(row: row, col: col): cell]) { a, _ in return a }
        }

        func isDay(k:CellCoord, v: [String: Any], day: String) -> Bool {
            guard
                k.col == 3,
                let cellDay = v["inputValue"] as? String,
                cellDay == day
            else {
                return false
            }

            return true
        }

        func item(r: Int) -> [String: Any] {
            let name = cells[CellCoord(row: r, col: 8)]?["inputValue"] as? String ?? ""
            let room = cells[CellCoord(row: r, col: 6)]?["inputValue"] as? String ?? ""
            let start = cells[CellCoord(row: r, col: 4)]?["$t"] as? String ?? ""
            let speaker = cells[CellCoord(row: r, col: 9)]?["inputValue"] as? String ?? ""
            let type = cells[CellCoord(row: r, col: 7)]?["inputValue"] as? String ?? ""
            let desc = cells[CellCoord(row: r, col: 10)]?["inputValue"] as? String ?? ""

            return [
                "name": name,
                "room": room,
                "start": start,
                "speaker": speaker,
                "type": type,
                "description": desc,
            ]
        }

        let day1Rows = cells.filter { (k, v) in isDay(k: k, v: v, day: "1") }.map { $0.key.row }.sorted()
        let day1Dicts = day1Rows.map(item)

        let day2Rows = cells.filter { (k, v) in isDay(k: k, v: v, day: "2") }.map { $0.key.row }.sorted()
        let day2Dicts = day2Rows.map(item)

        print("day1Rows: \(day1Rows.count)")
        print("day2Rows: \(day2Rows.count)")

        return [
            "1": day1Dicts,
            "2": day2Dicts,
        ]
    }

    class func parse(scheduleData: Data) -> [String: [Double: [ScheduleItem]]]? {
        if let json = try? JSONSerialization.jsonObject(with: scheduleData, options: []),
            let scheduleObject = parse(json: json)
             {

            var schedule = [String: [Double: [ScheduleItem]]]()

            let sat = scheduleObject["1"]?.compactMap { obj in
                return makeItemFromJSONObject(obj: obj, for: "1")
                } ?? [ScheduleItem]()
            schedule["1"] = getItems(forDay: "1", fromItems: sat)

            let sun = scheduleObject["2"]?.compactMap { obj in
                return makeItemFromJSONObject(obj: obj, for: "2")
                } ?? [ScheduleItem]()
            schedule["2"] = getItems(forDay: "2", fromItems: sun)
            return schedule
        }
        return nil
    }

    class func loadFromCache(completion: @escaping ([String: [Double: [ScheduleItem]]]) -> ()) {
        if let data = getCachedSchedule(), let schedule = parse(scheduleData: data) {
            completion(schedule)
        }
    }

    class func refresh(completion: @escaping () -> ()) {
        Schedule.load(session: Schedule.sharedInstance.session, completion: { (items) in
            Schedule.sharedInstance.items = items
            completion()
        })
    }

    class func load(session: URLSession?, completion: @escaping ([String: [Double: [ScheduleItem]]]) -> ()) {
        guard let session = session else {
            loadFromCache(completion: completion)
            return
        }
        let url = URL(string: "https://spreadsheets.google.com/feeds/cells/17EDt6Pu6xefcwT2C1UsYB7m0Ek-Vb1Us8Azfn3a_eso/1/public/full?alt=json")!

        let task = session.dataTask(with: url) { (data, response, error) in
            guard let scheduleData = data else {
                loadFromCache(completion: completion)
                return
            }
            if let schedule = parse(scheduleData: scheduleData) {
                Schedule.cacheSchedule(data: scheduleData)
                completion(schedule)
            } else {
                loadFromCache(completion: completion)
            }
        }
        task.resume()
    }

    func shouldInclude(item: ScheduleItem, withSearchTerm searchTerm: String) -> Bool {
        let terms = searchTerm.lowercased().split(separator: " ")
        for term in terms {
            if !item.session.lowercased().contains(String(term)) &&
                !item.room.contains(String(term)) &&
                !item.speaker.lowercased().contains(String(term)) &&
                !item.type.lowercased().contains(String(term)) {
                return false
            }
        }
        return true
    }

    func itemsGroupedByTimeFiltered(byDay day: String, searchTerm: String? = nil) -> [[ScheduleItem]] {
        let dayItems = self.items?[day] ?? [:];


        var groupedItems = [[ScheduleItem]]()
        for time in dayItems.keys.sorted() {
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
