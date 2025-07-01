//
//  QRScannerView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @State private var scannedItems: [String] = []
    
    var body: some View {
        VStack {
            // Превью камеры
            ZStack {
                QRScannerRepresentable(scannedCode: $viewModel.scannedCode)
                    .frame(height: 300)
                    .cornerRadius(12)
                    .padding()
                
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(height: 300)
                    .padding()
            }
            
            // Лента отсканированных кодов
            List(scannedItems.reversed(), id: \.self) { item in
                Text(item)
                    .padding()
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = item
                        }) {
                            Label("Копировать", systemImage: "doc.on.doc")
                        }
                    }
            }
            .listStyle(.plain)
            
            // Статус сканирования
            Text(viewModel.statusMessage)
                .foregroundColor(viewModel.statusColor)
                .padding()
        }
        .navigationTitle("QR Сканер")
        .onChange(of: viewModel.scannedCode) { newValue in
            if let code = newValue, !scannedItems.contains(code) {
                scannedItems.append(code)
                viewModel.scannedCode = nil // Сбрасываем для нового сканирования
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .onAppear {
            viewModel.checkCameraAuthorization()
        }
    }
}

// MARK: - ViewModel
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
            DispatchQueue.main.async {
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

// MARK: - UIKit Representable
struct QRScannerRepresentable: UIViewRepresentable {
    @Binding var scannedCode: String?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return view
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedCode: String?
        
        init(scannedCode: Binding<String?>) {
            self._scannedCode = scannedCode
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first,
               let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let code = readableObject.stringValue {
                scannedCode = code
            }
        }
    }
}

// MARK: - Предпросмотр
struct QRScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerView()
    }
}
