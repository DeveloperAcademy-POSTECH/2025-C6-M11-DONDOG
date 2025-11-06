//
//  HomePostModel.swift
//  DonDog-iOS
//
//  Created by Ito on 11/5/25.
//

import FirebaseCore
import Foundation

enum TimeType: String {
    case a = "A"
    case b = "B"
}

struct HomePost {
    let post: PostData
    let authorId: String
    var frontImageURL: URL?
    var backImageURL: URL?
    let isMyPost: Bool
    let timeType: TimeType
    
    init(
        post: PostData,
        frontImageURL: URL? = nil,
        backImageURL: URL? = nil,
        authorId: String,
        isMyPost: Bool
    ) {
        self.post = post
        self.frontImageURL = frontImageURL
        self.backImageURL = backImageURL
        self.authorId = authorId
        self.isMyPost = isMyPost
        
        let postDate = post.createdAt.dateValue()
        self.timeType = HomePost.determineTimeType(from: postDate)
    }
    
    var postId: String {
        post.postId
    }
    
    var createdAt: Date { post.createdAt.dateValue() }
    
    // MARK: - Static Methods (데이터 로직)
    
    static func determineTimeType(from date: Date) -> TimeType {
        return DateUtils.isATime(date: date) ? .a : .b
    }
    
    static func todayPosts(from posts: [HomePost]) -> [HomePost] {
        let today = Date()
        let startOfToday = DateUtils.startOfDay(for: today)
        let endOfToday = startOfToday.addingTimeInterval(24 * 60 * 60)
        
        return posts.filter { post in
            let postDate = post.createdAt
            return postDate >= startOfToday && postDate < endOfToday
        }
    }
    
    static func myLatestPost(from posts: [HomePost]) -> HomePost? {
        posts
            .filter { $0.isMyPost }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    static func partnerLatestPost(from posts: [HomePost]) -> HomePost? {
        posts
            .filter { !$0.isMyPost }
            .sorted { $0.createdAt > $1.createdAt }
            .first
    }
    
    static func currentPost(from posts: [HomePost], isShowingMyPost: Bool) -> HomePost? {
        isShowingMyPost ? myLatestPost(from: posts) : partnerLatestPost(from: posts)
    }
    
    static func postsByTimeType(from posts: [HomePost], timeType: TimeType) -> [HomePost] {
        posts.filter { post in
            let postTimeType = determineTimeType(from: post.createdAt)
            return postTimeType == timeType
        }
    }
}
