//
//  Model.swift
//  blog-ios12-performance
//
//  Created by ttillage on 6/9/18.
//  Copyright © 2018 CapTech. All rights reserved.
//

import Foundation
import NaturalLanguage

struct ArticlesResponse: Codable {
    let totalResults: Int
    let articles: [Article]
    var page: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalResults
        case articles
        case page
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalResults = try container.decode(Int.self, forKey: CodingKeys.totalResults)
        self.page = try container.decodeIfPresent(Int.self, forKey: CodingKeys.page)
        
        let articles = try container.decode([Article].self, forKey: CodingKeys.articles)
        self.articles = articles.filter({ $0.urlToImage != nil })
    }
}

struct Article: Codable {
    
    static let nameTagger = NLTagger(tagSchemes: [.nameType])
    static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }()
    
    let title: String
    let urlToImage: URL?
    let publishedAt: Date?
    
    let displayDate: String?
    let nameHighlightedTitle: NSAttributedString?
    
    enum CodingKeys: String, CodingKey {
        case title
        case urlToImage
        case publishedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let title = try container.decode(String.self, forKey: CodingKeys.title)
        self.title = title
        
        self.urlToImage = try container.decodeIfPresent(URL.self, forKey: CodingKeys.urlToImage)
        
        let publishedAt = try container.decodeIfPresent(Date.self, forKey: CodingKeys.publishedAt)
        self.publishedAt = publishedAt
        
        if let date = publishedAt {
            self.displayDate = Article.displayDateFormatter.string(from: date)
        } else {
            self.displayDate = nil
        }
        
        Article.nameTagger.string = title
        let range = title.startIndex ..< title.endIndex
        
        let tags = Article.nameTagger.tags(in: range, unit: .word, scheme: .nameType)
        
        let attrString = NSMutableAttributedString(string: title)
        for (tag, tagRange) in tags where tag == .personalName {
            let nsRange = (title as NSString).range(of: String(title[tagRange]))
            attrString.addAttribute(.underlineStyle, value: 1, range: nsRange)
        }
        self.nameHighlightedTitle = attrString
    }
    
    func cacheKey() -> String {
        return self.title.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "/", with: "").lowercased()
    }
}
