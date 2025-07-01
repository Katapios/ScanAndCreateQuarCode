//
//  RootView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI


struct RootView: View {
    @State private var tab = 0          // 0 = «Создать», 1 = «Сканировать»
    var body: some View {
        TabView(selection: $tab) {
            QRCodeGeneratorView()
                .tabItem { Label("Создать", systemImage: "qrcode") }
                .tag(0)                 // <- теги

            QRScannerView(tab: $tab)    // <- передаём binding
                .tabItem { Label("Сканировать", systemImage: "viewfinder") }
                .tag(1)
        }
    }
}


