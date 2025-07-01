//
//  QRCodeGeneratorView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import PhotosUI


// MARK: - View
struct QRCodeGeneratorView: View {
    @StateObject private var store = QRCodeStore()
    
    @State private var newText = ""
    @State private var editingItem: QRCodeItem?
    @State private var showActionSheet = false
    @State private var showSaveAlert  = false
    @State private var saveAlertMsg   = ""
    @State private var shareItems: [Any] = []     // содержимое шера
    @State private var showShareSheet = false
    @State private var imageSaver: ImageSaver?      // держим ссылку
    @FocusState private var isInputFocused: Bool
    
    private var hasSelection: Bool {store.items.contains { $0.isSelected }}
    
    private func presentShareSheet() {
        let images = store.getSelectedImages()
        guard !images.isEmpty else { return }
        shareItems = images                       // можно миксовать и Text/URL
        showShareSheet = true
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputSection
                Divider()
                actionButtons
                savedCodesList
            }
            .navigationTitle("QR Generator")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if hasSelection {
                        Button(action: presentShareSheet) {        // 👈
                            Image(systemName: "square.and.arrow.up")
                        }
                        Button(role: .destructive, action: { showActionSheet = true }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(item: $editingItem) { EditQRView(item: $0, store: store) }
            .sheet(isPresented: $showShareSheet) {
                ActivityView(items: shareItems)
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(title: Text("Удалить выбранные QR-коды?"),
                            buttons: [.destructive(Text("Удалить"), action: store.deleteSelected),
                                      .cancel()])
            }
            .alert("Сохранение", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: { Text(saveAlertMsg) }
        }
        .simultaneousGesture(                          // ← добавлено
            TapGesture().onEnded {                     // жест «любой тап»
                isInputFocused = false                 // снимаем фокус ⇒ клавиатура прячется
            }
        )
    }
    
    // MARK: UI-блоки
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Enter text or URL", text: $newText)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                .focused($isInputFocused)
                .onSubmit(generateQR)
            
            Button(action: generateQR) {
                Image(systemName: "qrcode")
                    .font(.system(size: 24))
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .foregroundColor(.white)
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
        }
        .padding(.vertical, 8)
        .opacity(store.items.isEmpty ? 0 : 1)
    }
    
    private var savedCodesList: some View {
        List {
            ForEach(store.items) { item in
                QRCodeRow(item: item,
                          isSelected: Binding(get: { item.isSelected },
                                              set: { store.setSelected($0, forId: item.id) }),
                          onEdit: { editingItem = item })
                .onAppear {
                    if item.id == store.items.last?.id { store.loadMoreItems() }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { store.deleteItem(item.id) } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                }
            }
            .onDelete(perform: store.deleteItem(at:))
        }
        .listStyle(.plain)
    }
    
    // MARK: Логика
    
    private func generateQR() {
        let text = newText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(text.utf8), forKey: "inputMessage")
        guard let output = filter.outputImage else { return }
        
        let scaled = output.transformed(by: .init(scaleX: 10, y: 10))
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return }
        
        store.addItem(text: text, image: UIImage(cgImage: cg))
        newText = ""
        isInputFocused = false
    }
    
    private func saveSelectedToGallery() {
        let images = store.getSelectedImages()
        guard !images.isEmpty else { return }
        
        func startSaving() {
            let saver = ImageSaver(total: images.count) { ok, fail in
                saveAlertMsg = "Сохранено \(ok) из \(images.count). Ошибок: \(fail)"
                showSaveAlert = true
                store.deselectAll()
                imageSaver = nil                       // освобождаем ссылку
            }
            imageSaver = saver                        // удерживаем
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
    // MARK: - Редактирование QR-кода
    struct EditQRView: View {
        @Environment(\.dismiss) var dismiss
        let item: QRCodeItem
        let store: QRCodeStore
        
        @State private var editedText: String
        
        init(item: QRCodeItem, store: QRCodeStore) {
            self.item = item
            self.store = store
            self._editedText = State(initialValue: item.text)
        }
        
        var body: some View {
            NavigationStack {
                Form {
                    Section {
                        TextField("Текст", text: $editedText)
                    }
                    
                    Section {
                        if let image = item.image {
                            Image(uiImage: image)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                    
                    Section {
                        Button("Сохранить изменения") {
                            store.updateItem(item.id, newText: editedText)
                            dismiss()
                        }
                        .disabled(editedText.isEmpty || editedText == item.text)
                    }
                }
                .navigationTitle("Редактировать QR-код")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Предпросмотр
    struct QRCodeGeneratorView_Previews: PreviewProvider {
        static var previews: some View {
            QRCodeGeneratorView()
        }
    }
}

#Preview {
    QRCodeGeneratorView()
}
