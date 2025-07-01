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
    var imagePath: String?           // заменено imageData на путь к файлу
    var isSelected: Bool = false

    var image: UIImage? {
        guard let path = imagePath else { return nil }
        return UIImage(contentsOfFile: path)
    }
}
