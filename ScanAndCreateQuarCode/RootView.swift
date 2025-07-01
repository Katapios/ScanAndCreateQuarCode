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
            QRCodeGeneratorView()
                .tabItem { Label("Создать", systemImage: "qrcode") }
            
            QRScannerView()                // ← новый экран
                .tabItem { Label("Сканировать", systemImage: "viewfinder") }
        }
    }
}

#Preview {
    RootView()
}
