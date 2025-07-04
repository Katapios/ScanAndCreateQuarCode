//
//  QRScannerView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import AVFoundation
import CoreImage.CIFilterBuiltins        // 👈 для генерации QR

struct QRScannerView: View {
    @EnvironmentObject private var scanStore: QRScanStore
    @EnvironmentObject private var codeStore: QRCodeStore   // 👈 доступ к генератору
    @StateObject private var viewModel = QRScannerViewModel()
    @Binding var tab: Int

    // UI-состояния
    @State private var editingItem: QRCodeItem?
    @State private var showDeleteSheet = false

    private var hasSelection: Bool { scanStore.items.contains { $0.isSelected } }
    private let ciContext = CIContext()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                cameraPreview
                Divider()
                actionButtons
                codesScroll
            }
            .navigationTitle("QR Сканер")
            .toolbar { trailingToolbar }
            .sheet(item: $editingItem) { item in
                // можем переиспользовать уже готовый редактор
                EditQRItemView(item: item, store: scanStore)
            }
            .confirmationDialog("Удалить выбранные QR-коды?",
                                isPresented: $showDeleteSheet,
                                titleVisibility: .visible) {
                Button("Удалить", role: .destructive, action: scanStore.deleteSelected)
            }
        }
        .onChange(of: viewModel.scannedCode) { addScanned($0) }
        .onAppear { viewModel.checkCameraAuthorization() }
    }

    // MARK: UI-секции ---------------------------------------------------------

    private var cameraPreview: some View {
        ZStack {
            QRScannerRepresentable(scannedCode: $viewModel.scannedCode)
                .frame(height: 300)
                .cornerRadius(12)
                .padding()

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 2)
                .frame(height: 300)
                .padding()

            VStack {
                Spacer()
                Text(viewModel.statusMessage)
                    .foregroundColor(viewModel.statusColor)
                    .padding(.bottom, 150)
            }
        }
    }

        private var actionButtons: some View {
            HStack {
                Button("Выбрать все",  action: scanStore.selectAll).font(.caption)
                Button("Снять выбор",  action: scanStore.deselectAll).font(.caption)
    
                Button("На главную") { moveSelectedToGenerator() }  // стало
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

    // MARK: Логика ------------------------------------------------------------

    /// Добавляем новый код в стор и даём тактильный отклик
    private func addScanned(_ code: String?) {
        guard let code, !scanStore.all.contains(where: { $0.text == code }) else { return }
        scanStore.add(text: code, image: nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        viewModel.scannedCode = nil
    }
    
    // MARK: – Перенос выбранных кодов в генератор -------------------------------
    private func moveSelectedToGenerator() {
        let selected = scanStore.items.filter(\.isSelected)

        for item in selected {
            guard !codeStore.all.contains(where: { $0.text == item.text }) else { continue }
            if let qr = makeQR(from: item.text) {
                codeStore.addItem(text: item.text, image: qr)
            }
        }

        codeStore.loadMore()         // ← важная строка
        scanStore.deselectAll()
        tab = 0                      // переключаемся на генератор
    }

    /// Генерирует QR-картинку из текста
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
        .environmentObject(QRCodeStore())   // нужен и второй стор
}
