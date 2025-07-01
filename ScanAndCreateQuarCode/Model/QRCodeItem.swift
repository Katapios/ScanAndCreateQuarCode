//
//  QRCodeItem.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

// MARK: - Модель
struct QRCodeItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var imageData: Data?
    var isSelected: Bool = false
    
    var image: UIImage? {
        imageData.flatMap { UIImage(data: $0) }
    }
}
