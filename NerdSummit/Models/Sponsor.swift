//
//  Sponsor.swift
//  NerdSummit
//
//  Created by Louis Franco on 1/30/19.
//  Copyright © 2019 Lou Franco. All rights reserved.
//

import Foundation

struct Sponsor {
    let sponsor: String
    let logo: String
    let level: String
}

struct SponsorsAtLevel {
    let level: String
    var sponsors: [Sponsor]
}

class Sponsors {
    static let sharedInstance = Sponsors()
    var session: URLSession? = nil

    var items = [SponsorsAtLevel]()

    init() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        session = URLSession(configuration: config)
    }

    func update(completion: @escaping ([SponsorsAtLevel]) -> ()) {
        Sponsors.load(session: session, completion: { (items) in
            self.items = items
            completion(items)
        })
    }

    class func documentsFolder() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    class func sponsorsFilePath() -> URL {
        return documentsFolder().appendingPathComponent("sponsors.json")
    }

    class func cacheSponsors(data: Data) {
        try? data.write(to: sponsorsFilePath())
    }

    class func getCachedSponsors() -> Data? {
        return try? Data(contentsOf: sponsorsFilePath())
    }

    class func parse(sponsorsData: Data) -> [SponsorsAtLevel]? {
        // .feed.entry[0]."gs$cell"
        guard
            let json = try? JSONSerialization.jsonObject(with: sponsorsData, options: []),
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

        let rows = cells.filter { (k, v) in
            guard
                k.col == 1,
                let cellIdString = v["inputValue"] as? String,
                let _ = Int(cellIdString)
            else {
                return false
            }

            return true
        }.map { $0.key.row }.sorted()

        func item(r: Int) -> Sponsor {
            let sponsor = cells[CellCoord(row: r, col: 5)]?["inputValue"] as? String ?? ""
            let logo = cells[CellCoord(row: r, col: 4)]?["inputValue"] as? String ?? ""
            let level = cells[CellCoord(row: r, col: 2)]?["inputValue"] as? String ?? ""

            return Sponsor(sponsor: sponsor, logo: logo, level: level)
        }

        let result = rows.map(item).reduce([SponsorsAtLevel]()) { (r, sponsor) -> [SponsorsAtLevel] in
            let level = sponsor.level
            var result = r

            if let i = r.firstIndex(where: { $0.level == level}) {
                var sponsorAtLevel = r[i]
                sponsorAtLevel.sponsors.append(sponsor)
                result[i] = sponsorAtLevel
            } else {
                result.append(SponsorsAtLevel(level: level, sponsors: [sponsor]))
            }
            return result
        }

        return result
    }


    class func loadFromCache(completion: @escaping ([SponsorsAtLevel]) -> ()) {
        if let data = getCachedSponsors(), let sponsors = parse(sponsorsData: data) {
            completion(sponsors)
        }
    }

    class func refresh(completion: @escaping () -> ()) {
        Sponsors.load(session: Sponsors.sharedInstance.session, completion: { (items) in
            Sponsors.sharedInstance.items = items
            completion()
        })
    }

    class func load(session: URLSession?, completion: @escaping ([SponsorsAtLevel]) -> ()) {
        guard let session = session else {
            loadFromCache(completion: completion)
            return
        }
        let url = URL(string: "https://spreadsheets.google.com/feeds/cells/1_eUwlDMFUI8dX_5R-ZEs32ze-4NwkNoO9X8CkX-riOk/1/public/full?alt=json")!

        let task = session.dataTask(with: url) { (data, response, error) in
            guard let sponsorsData = data else {
                loadFromCache(completion: completion)
                return
            }
            if let schedule = parse(sponsorsData: sponsorsData) {
                Sponsors.cacheSponsors(data: sponsorsData)
                completion(schedule)
            } else {
                loadFromCache(completion: completion)
            }
        }
        task.resume()
    }

}
