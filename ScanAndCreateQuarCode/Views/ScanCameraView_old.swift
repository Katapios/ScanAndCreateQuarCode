//
//  ScanCameraView.swift
//  ScanAndCreateQuarCode
//

import SwiftUI
import VisionKit                 // iOS 16 SDK

/// Камера-сканер QR-кодов (минимум iOS 16).
struct ScanCameraView: UIViewControllerRepresentable {
    
    /// Возвращает текст внутри QR-кода.
    let onDetect: (_ payload: String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: UIViewControllerRepresentable
    func makeCoordinator() -> Coordinator {
        Coordinator(onDetect: onDetect, dismiss: dismiss)
    }
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let vc = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        vc.delegate = context.coordinator
        try? vc.startScanning()
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController,
                                context: Context) {}
}

// MARK: – Coordinator
@available(iOS 16, *)
final class Coordinator: NSObject, DataScannerViewControllerDelegate {
    
    private let onDetect: (String) -> Void
    private let dismiss: DismissAction
    private var isHandled = false              // чтобы вызвать callback один раз
    
    init(onDetect: @escaping (String) -> Void,
         dismiss: DismissAction) {
        self.onDetect = onDetect
        self.dismiss  = dismiss
    }
    
    // Первый приход (часто без payload)
    func dataScanner(_ scanner: DataScannerViewController,
                     didAdd items: [RecognizedItem]) {
        handle(items)
    }
    
    // Повторные обновления — здесь payload почти всегда заполнен
    func dataScanner(_ scanner: DataScannerViewController,
                     didUpdate items: [RecognizedItem]) {
        handle(items)
    }
    
    // MARK: - Общая обработка
    private func handle(_ items: [RecognizedItem]) {
        guard !isHandled,
              let first = items.first,
              case .barcode(let code) = first,
              let payload = code.payloadStringValue,
              !payload.isEmpty
        else { return }
        
        isHandled = true
        DispatchQueue.main.async {
            self.onDetect(payload)
            self.dismiss()
        }
    }
}
