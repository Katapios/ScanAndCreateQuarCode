//
//  QRScannerView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins

struct QRScannerView: View {
    @EnvironmentObject private var scanStore: QRScanStore
    @EnvironmentObject private var codeStore: QRCodeStore
    @StateObject private var viewModel = QRScannerViewModel()
    @Binding var tab: Int

    @State private var editingItem: QRCodeItem?
    @State private var showDeleteSheet = false

    private var hasSelection: Bool { scanStore.items.contains { $0.isSelected } }
    private let ciContext = CIContext()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("QR Code Scanner")
                        .font(.title2).bold()
                        .foregroundColor(.primary)
                    Text("Сканируйте QR-коды для добавления в коллекцию.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)

                CameraPreview(session: viewModel)
                    .frame(height: 220)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
                    .padding(.horizontal, 24)
                    .onAppear {
                        viewModel.setupSession()
                        viewModel.startSession()
                    }

                actionButtons

                if scanStore.items.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Нет отсканированных кодов")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    codesScroll
                }
            }
            .padding(.bottom, 8)
            .toolbar { trailingToolbar }
            .sheet(item: $editingItem) { item in
                EditQRItemView(item: item, store: scanStore)
            }
            .confirmationDialog("Удалить выбранные QR-коды?",
                                isPresented: $showDeleteSheet,
                                titleVisibility: .visible) {
                Button("Удалить", role: .destructive, action: scanStore.deleteSelected)
            }
            .onReceive(viewModel.$scannedCode.compactMap { $0 }) { code in
                addScanned(code)
                viewModel.resetScannedCode()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
        .edgesIgnoringSafeArea(.top)
    }

    struct CameraPreview: UIViewRepresentable {
        @ObservedObject var session: QRScannerViewModel

        func makeUIView(context: Context) -> UIView {
            let view = UIView()
            let previewLayer = session.makePreviewLayer()
            previewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(previewLayer)
            return view
        }

        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
        @Published var scannedCode: String? = nil

        private let session = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?

        func setupSession() {
            guard session.inputs.isEmpty else { return }
            guard let videoDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
            if session.canAddInput(videoInput) { session.addInput(videoInput) }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
        }

        func startSession() {
            if !session.isRunning {
                session.startRunning()
            }
        }

        func stopSession() {
            if session.isRunning {
                session.stopRunning()
            }
        }

        func makePreviewLayer() -> AVCaptureVideoPreviewLayer {
            if let previewLayer = previewLayer { return previewLayer }
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            return layer
//            previewLayer = layer
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
               let stringValue = object.stringValue {
                scannedCode = stringValue
                // Do not stopSession() here if you want continuous scanning
            }
        }

        func resetScannedCode() {
            scannedCode = nil
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Выбрать все",  action: scanStore.selectAll).font(.caption)
            Button("Снять выбор",  action: scanStore.deselectAll).font(.caption)
            Button("На главную") { moveSelectedToGenerator() }
                .font(.caption)
                .disabled(!hasSelection)
        }
        .padding(.vertical, 8)
        .opacity(scanStore.items.isEmpty ? 0 : 1)
    }

    private var codesScroll: some View {
        ScrollView {
            LazyVStack {
                ForEach(scanStore.items) { item in
                    QRCodeRow(item: item,
                              isSelected: Binding(
                                get: { item.isSelected },
                                set: { scanStore.set(item.id, selected: $0) }),
                              onEdit: { editingItem = item })
                    .onAppear {
                        if item.id == scanStore.items.last?.id { scanStore.loadMore() }
                    }
                    .swipeActions {
                        Button(role: .destructive) { scanStore.delete(item.id) } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var trailingToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            if hasSelection {
                Button(role: .destructive) { showDeleteSheet = true } label: {
                    Image(systemName: "trash")
                }
            }
        }
    }

    private func addScanned(_ code: String?) {
        guard let code, !scanStore.all.contains(where: { $0.text == code }) else { return }
        scanStore.add(text: code, image: nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        // Do not reset scannedCode here, handled by resetScannedCode()
    }

    private func moveSelectedToGenerator() {
        let selected = scanStore.items.filter(\.isSelected)
        for item in selected {
            guard !codeStore.all.contains(where: { $0.text == item.text }) else { continue }
            if let qr = makeQR(from: item.text) {
                codeStore.addItem(text: item.text, image: qr)
            }
        }
        codeStore.loadMore()
        scanStore.deselectAll()
        tab = 0
    }

    private func makeQR(from text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        guard let cg = ciContext.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

#Preview {
    QRScannerView(tab: .constant(1))
        .environmentObject(QRScanStore())
        .environmentObject(QRCodeStore())
}
