//
//  QRItemUpdatable.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import Foundation

@MainActor                     // ← добавили
protocol QRItemUpdatable: AnyObject {
    func update(_ id: UUID, newText: String)
}
