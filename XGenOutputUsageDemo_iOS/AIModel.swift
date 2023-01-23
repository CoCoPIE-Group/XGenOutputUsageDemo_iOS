//
//  AIModel.swift
//  XGenOutputUsageDemo_iOS
//
//  Created by steven on 2023/1/22.
//

import Foundation

class AIModel: Decodable {
    let name: String
    let labelURL: URL
    let fallbackURL: URL
    let isLocal: Bool
    
    init(name: String, labelURL: URL, fallbackURL: URL, isLocal: Bool) {
        self.name = name
        self.labelURL = labelURL
        self.fallbackURL = fallbackURL
        self.isLocal = isLocal
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let urls = try container.nestedContainer(keyedBy: InnerCodingKeys.self, forKey: .urls)
        
        let labelString = try urls.decode(String.self, forKey: .labelURL)
        labelURL = URL(string: labelString)!
        
        let fallbackString = try urls.decode(String.self, forKey: .fallbackURL)
        fallbackURL = URL(string: fallbackString)!
        
        isLocal = false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        var urls = container.nestedContainer(keyedBy: InnerCodingKeys.self, forKey: .urls)
        try urls.encode(labelURL, forKey: .labelURL)
        try urls.encode(fallbackURL, forKey: .fallbackURL)
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case urls
    }
    
    enum InnerCodingKeys: String, CodingKey {
        case labelURL = "labels"
        case fallbackURL = "fallback"
    }
}
