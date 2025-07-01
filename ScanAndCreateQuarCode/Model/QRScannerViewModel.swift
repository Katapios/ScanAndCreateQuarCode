//
//  QRScannerViewModel.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import AVFoundation

@MainActor
class QRScannerViewModel: ObservableObject {
    @Published var scannedCode: String?
    @Published var statusMessage = "Наведите камеру на QR-код"
    @Published var statusColor: Color = .primary

    func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            statusMessage = "Камера доступна"
            statusColor = .green
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            statusMessage = "Нет доступа к камере. Проверьте настройки."
            statusColor = .red
        @unknown default:
            statusMessage = "Неизвестный статус доступа"
            statusColor = .orange
        }
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            Task { @MainActor in
                if granted {
                    self.statusMessage = "Камера доступна"
                    self.statusColor = .green
                } else {
                    self.statusMessage = "Доступ к камере запрещен"
                    self.statusColor = .red
                }
            }
        }
    }
}

