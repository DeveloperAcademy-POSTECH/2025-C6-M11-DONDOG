//
//  CameraViewModel.swift
//  DonDog-iOS
//
//  Created by 조유진 on 10/3/25.
//

import Combine
import UIKit
import SwiftUI

protocol CameraViewModelDelegate: AnyObject {
    func didCaptureImages(frontImage: UIImage, backImage: UIImage)
}

final class CameraViewModel: ObservableObject {
    weak var delegate: CameraViewModelDelegate?
    var frontImage: UIImage?
    var backImage: UIImage?
}
