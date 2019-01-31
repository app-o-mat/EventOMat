//
//  Sponsor.swift
//  EventOMat
//
//  Created by Louis Franco on 1/30/19.
//  Copyright © 2019 Lou Franco. All rights reserved.
//

import Foundation

struct Sponsor {
    let sponsor: String
    let logo: String
}

struct SponsorsAtLevel {
    let level: String
    let sponsors: [Sponsor]
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
        if let json = try? JSONSerialization.jsonObject(with: sponsorsData, options: []),
            let sponsorsObject = json as? [[String: Any]] {

            var result = [SponsorsAtLevel]()
            for sponsorsAtLevel in sponsorsObject {
                guard
                    let level = sponsorsAtLevel["level"] as? String,
                    let sponsors = sponsorsAtLevel["sponsors"] as? [[String: String]]
                else {
                    continue
                }

                var sponsorArray = [Sponsor]()
                for s in sponsors {
                    guard
                        let sponsor = s["sponsor"],
                        let logo = s["logo"]
                        else {
                            continue
                    }
                    sponsorArray.append(Sponsor(sponsor: sponsor, logo: logo))
                }
                let newLevel = SponsorsAtLevel(level: level, sponsors: sponsorArray)
                result.append(newLevel)
            }
            return result
        }
        return nil
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
        let url = URL(string: "https://nerdsummit.org/data/sponsors.json")!

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
