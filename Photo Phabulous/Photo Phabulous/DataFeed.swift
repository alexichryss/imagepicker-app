//
//  DataFeed.swift
//  Photo Phabulous
//
//  Created by Alexi Chryssanthou on 2/23/18.
//  Copyright © 2018 Alexi Chryssanthou. All rights reserved.
//

import Foundation

struct DataFeed: Codable {

    var urlPrefix: String?
    var results: [ImageData?]
    
}

struct ImageData: Codable {
    
    var date: String? = "no date"
    var caption: String? = "no caption"
    var image_url: String? = "no image_url"
    var user: String? = "no user"
    var missing: Bool?
}
