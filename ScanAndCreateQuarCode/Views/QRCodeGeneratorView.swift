//
//  QRCodeGeneratorView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import PhotosUI

struct QRCodeGeneratorView: View {
    @EnvironmentObject private var store: QRCodeStore

    @State private var newText = ""
    @State private var editingItem: QRCodeItem?
    @State private var showDeleteSheet = false
    @State private var showSaveAlert  = false
    @State private var saveAlertMsg   = ""
    @State private var shareItems: [Any] = []
    @State private var sharePayload: SharePayload?
    @State private var imageSaver: ImageSaver?
    @FocusState private var isInputFocused: Bool

    private var hasSelection: Bool { store.items.contains { $0.isSelected } }
    private let ciContext = CIContext()          // единый контекст

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputSection
                Divider()
                actionButtons
                codesScroll
            }
            .navigationTitle("QR Generator")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if hasSelection {
                        Button(action: presentShareSheet) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button(role: .destructive) { showDeleteSheet = true } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                EditQRItemView(item: item, store: store)
            }
            .sheet(item: $sharePayload) { payload in
                ActivityView(items: payload.items)
            }
            .confirmationDialog("Удалить выбранные QR-коды?",
                                isPresented: $showDeleteSheet,
                                titleVisibility: .visible) {
                Button("Удалить", role: .destructive, action: store.deleteSelected)
            }
            .alert("Сохранение", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(saveAlertMsg) }
        }
        .simultaneousGesture(
            TapGesture().onEnded { isInputFocused = false }
        )
    }

    // MARK: – UI-секции -------------------------------------------------------

    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Enter text or URL", text: $newText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .focused($isInputFocused)
                .onSubmit { Task { await generateQR() } }

            Button { Task { await generateQR() } } label: {
                Image(systemName: "qrcode")
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding()
    }

    private var actionButtons: some View {
        HStack {
            Button("Выбрать все",  action: store.selectAll).font(.caption)
            Button("Снять выбор",  action: store.deselectAll).font(.caption)
            Button("В Фото", action: saveSelectedToGallery).font(.caption)
        }
        .padding(.vertical, 8)
        .opacity(store.items.isEmpty ? 0 : 1)
    }

    private var codesScroll: some View {
        ScrollView {
            LazyVStack {
                ForEach(store.items) { item in
                    QRCodeRow(item: item,
                              isSelected: Binding(
                                get: { item.isSelected },
                                set: { store.setSelected($0, forId: item.id) }),
                              onEdit: { editingItem = item })
                    .onAppear {
                        if item.id == store.items.last?.id { store.loadMore() }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { store.deleteItem(item.id) } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: – Логика ----------------------------------------------------------

    private func generateQR() async {
        let text = newText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return }

        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        guard let cg = ciContext.createCGImage(scaled, from: scaled.extent) else { return }

        store.addItem(text: text, image: UIImage(cgImage: cg))
        newText = ""
        isInputFocused = false
    }

    private func presentShareSheet() {
        let images = store.getSelectedImages()
        guard !images.isEmpty else { return }
        sharePayload = SharePayload(items: images)      // новый экземпляр
    }

    private func saveSelectedToGallery() {
        let images = store.getSelectedImages()
        guard !images.isEmpty else { return }

        func startSaving() {
            let saver = ImageSaver(total: images.count) { ok, fail in
                saveAlertMsg = "Сохранено \(ok) из \(images.count). Ошибок: \(fail)"
                showSaveAlert = true
                store.deselectAll()
                imageSaver = nil
            }
            imageSaver = saver
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
            saveAlertMsg = "Доступ к Фото запрещён. Разреши в Настройках."
            showSaveAlert = true
        }
    }
}

#Preview { QRCodeGeneratorView().environmentObject(QRCodeStore()) }
