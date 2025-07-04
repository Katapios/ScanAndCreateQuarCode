//
//  QRScannerViewModel.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import AVFoundation
import SwiftUI

class QRScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String? = nil
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var lastScannedCode: String?

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
        previewLayer = layer
        return layer
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = object.stringValue {
            // Only set if different from last scanned
            if lastScannedCode != stringValue {
                scannedCode = stringValue
                lastScannedCode = stringValue
            }
        }
    }

    // Call this after processing the code in your view
    func resetScannedCode() {
        scannedCode = nil
        lastScannedCode = nil
    }
}
