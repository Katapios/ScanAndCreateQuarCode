//
//  SharePayload.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import Foundation

struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}
