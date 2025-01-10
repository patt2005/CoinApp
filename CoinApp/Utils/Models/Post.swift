//
//  Post.swift
//  CoinApp
//
//  Created by Petru Grigor on 08.01.2025.
//

import Foundation

struct Post: Decodable, Hashable {
    struct Owner: Decodable, Hashable {
        struct Avatar: Decodable, Hashable {
            let url: String
        }
        
        let nickname: String
        let avatar: Avatar
    }
    
    struct ImageUrlData: Decodable, Hashable {
        let url: String
    }
    
    let textContent: String
    let impressionCount: String
    let likeCount: String
    let repostCount: String
    let postTime: String
    let owner: Owner
    let images: [ImageUrlData]?
}
