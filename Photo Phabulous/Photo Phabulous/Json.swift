//
//  Json.swift
//  Photo Phabulous
//
//  Created by Alexi Chryssanthou on 2/25/18.
//  Copyright © 2018 Alexi Chryssanthou. All rights reserved.
//

import Foundation

class Json: NSObject, NSCoding {
    
    var feed: Data
    
    // Memberwise initializer
    init(feed: Data) {
        self.feed = feed
    }
    
    // MARK: - NSCoding
    required convenience init?(coder decoder: NSCoder) {
        guard let feed = decoder.decodeObject(forKey: "feed") as? Data else {
            // Alternative use a coalescing operator
            // feed = aDecoder.decodeObjectForKey("feed") as? String ?? ""
            return nil
        }
        self.init(feed: feed)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.feed, forKey: "feed")
    }
}
