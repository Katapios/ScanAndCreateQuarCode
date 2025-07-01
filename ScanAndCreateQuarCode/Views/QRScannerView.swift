//
//  QRScannerView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct QRScannerView: View {
    @EnvironmentObject private var scanStore: QRScanStore
    @StateObject private var viewModel = QRScannerViewModel()

    // UI-состояния
    @State private var editingItem: QRCodeItem?
    @State private var showDeleteSheet = false
    @State private var sharePayload: SharePayload?        // для share-sheet

    private var hasSelection: Bool { scanStore.items.contains { $0.isSelected } }

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
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: payload.items)
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
                    .padding(.bottom, 12)
            }
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Выбрать все",  action: scanStore.selectAll).font(.caption)
            Button("Снять выбор",  action: scanStore.deselectAll).font(.caption)
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
                Button(action: presentShare) {
                    Image(systemName: "square.and.arrow.up")
                }
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

    /// Шаринг выбранных элементов (текст + изображения, если есть)
    private func presentShare() {
        let images = scanStore.selectedImages()
        let texts  = scanStore.items
            .filter { $0.isSelected }
            .map(\.text)
        guard !images.isEmpty || !texts.isEmpty else { return }

        sharePayload = SharePayload(items: images + texts)
    }
}


#Preview {
    QRScannerView()
        .environmentObject(QRScanStore())
}
