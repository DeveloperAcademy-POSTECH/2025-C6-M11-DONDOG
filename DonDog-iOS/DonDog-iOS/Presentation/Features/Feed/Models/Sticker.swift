//
//  Sticker.swift
//  DonDog-iOS
//
//  Created by 이서현 on 10/15/25.
//

struct Sticker: Codable {
    var imageURL: String
    var maskURL: String
    var type: String

    init(imageURL: String, maskURL: String, type: String = "null") {
        self.imageURL = imageURL
        self.maskURL = maskURL
        self.type = type
    }
}
