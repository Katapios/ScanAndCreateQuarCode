//
//  ScanAndCreateQuarCodeApp.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 30.06.2025.
//

import SwiftUI

@main
struct ScanAndCreateQuarCodeApp: App {
    @StateObject private var codeStore = QRCodeStore()
    @StateObject private var scanStore = QRScanStore()  // 👈 обязательно

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(codeStore)
                .environmentObject(scanStore)   // 👈 ВАЖНО: передаём сюда
        }
    }
}
