//
//  QRItemUpdatable.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import Foundation

// 1️⃣ Протокол
protocol QRItemUpdatable: AnyObject {
    func update(_ id: UUID, newText: String)
}

// 2️⃣ Расширяем генератор
extension QRCodeStore: QRItemUpdatable {
    func update(_ id: UUID, newText: String) {
        // переадресуем на существующий updateItem
        updateItem(id, newText: newText)
    }
}

// 3️⃣ Расширяем сканер
extension QRScanStore: QRItemUpdatable {
    func update(_ id: UUID, newText: String) {
        // у тебя в QRScanStore уже есть метод update(_:text:)
        update(id, text: newText)
    }
}
