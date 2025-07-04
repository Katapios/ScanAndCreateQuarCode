//
//  QRCodeGeneratorViewModel.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 04.07.2025.
//

import SwiftUI
import PhotosUI

class QRCodeGeneratorViewModel: ObservableObject {
    @Published var showSaveAlert = false
    @Published var saveAlertMsg = ""
    @Published var imageSaver: ImageSaver?

    func saveSelectedToGallery(images: [UIImage], onComplete: @escaping () -> Void) {
        guard !images.isEmpty else { return }

        func startSaving() {
            let saver = ImageSaver(total: images.count) { ok, fail in
                self.saveAlertMsg = "Сохранено \(ok) из \(images.count). Ошибок: \(fail)"
                self.showSaveAlert = true
                self.imageSaver = nil
                onComplete()
            }
            self.imageSaver = saver
            images.forEach { saver.writeToPhotoAlbum(image: $0) }
        }

        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            startSaving()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async { startSaving() }
                }
            }
        default:
            self.saveAlertMsg = "Доступ к Фото запрещён. Разреши в Настройках."
            self.showSaveAlert = true
        }
    }
}
