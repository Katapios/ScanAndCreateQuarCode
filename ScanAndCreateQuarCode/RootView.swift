//
//  RootView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            // 1. Генератор
            QRCodeGeneratorView()
                .tabItem {
                    Label("Создать", systemImage: "qrcode")
                }

            // 2. Сканер (пока заглушка)
            QRScannerPlaceholderView()
                .tabItem {
                    Label("Сканировать", systemImage: "viewfinder")
                }
        }
    }
}

#Preview {
    RootView()
}
