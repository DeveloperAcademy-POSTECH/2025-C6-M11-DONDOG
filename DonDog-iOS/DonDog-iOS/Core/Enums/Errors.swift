//
//  Errors.swift
//  DonDog-iOS
//
//  Created by 조유진 on 11/1/25.
//

import SwiftUI

// 기능 확장 시 에러들이 추가되면 각 기능별로 분리
enum PostServiceError: LocalizedError {
    case unauthorized
    case postNotFound
    case invalidIdentifier
}

enum DataManagerError: LocalizedError {
    case invalidPath
    case documentNotFound
    case decodingFailed
    case imageConversionFailed
    case uploadFailed
    case downloadFailed
    case authenticationRequired
    case userDocumentNotFound
    case roomIdNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidPath: return "잘못된 경로입니다"
        case .documentNotFound: return "문서를 찾을 수 없습니다"
        case .decodingFailed: return "데이터 변환에 실패했습니다"
        case .imageConversionFailed: return "이미지 변환에 실패했습니다"
        case .uploadFailed: return "업로드에 실패했습니다"
        case .downloadFailed: return "다운로드에 실패했습니다"
        case .authenticationRequired: return "로그인이 필요합니다"
        case .userDocumentNotFound: return "사용자 문서를 찾을 수 없습니다"
        case .roomIdNotFound: return "roomId를 찾을 수 없습니다"
        }
    }
}
