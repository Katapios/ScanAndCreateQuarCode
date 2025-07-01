//
//  QRScannerPlaceholderView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

struct QRScannerPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Режим сканирования появится в следующей версии.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Сканировать QR")
        }
    }
}
