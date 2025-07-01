import SwiftUI
import CoreImage.CIFilterBuiltins
import PhotosUI

// MARK: - Модель
struct QRCodeItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var imageData: Data?
    var isSelected: Bool = false
    
    var image: UIImage? {
        imageData.flatMap { UIImage(data: $0) }
    }
}

// MARK: - Хранилище
final class QRCodeStore: ObservableObject {
    @Published private(set) var items: [QRCodeItem] = []
    
    private var allItems: [QRCodeItem] = []
    private let batchSize = 15
    private var loadedCount = 0
    
    init() {
        loadAllItems()
        loadMoreItems()
    }
    
    // --- выбор
    func setSelected(_ isSelected: Bool, forId id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isSelected = isSelected
    }
    func selectAll()    { items.indices.forEach { items[$0].isSelected = true  } }
    func deselectAll()  { items.indices.forEach { items[$0].isSelected = false } }
    
    // --- подгрузка
    private func loadAllItems() {
        if let data = UserDefaults.standard.data(forKey: "qrcodes"),
           let decoded = try? JSONDecoder().decode([QRCodeItem].self, from: data) {
            allItems = decoded.sorted { $0.text < $1.text }
        }
    }
    func loadMoreItems() {
        guard loadedCount < allItems.count else { return }
        let next = allItems[loadedCount..<min(loadedCount + batchSize, allItems.count)]
        items.append(contentsOf: next)
        loadedCount += next.count
    }
    
    // --- CRUD
    func addItem(text: String, image: UIImage) {
        let new = QRCodeItem(text: text, imageData: image.pngData())
        allItems.insert(new, at: 0)
        items.insert(new, at: 0)
        loadedCount += 1                  // ← фикс двойной генерации
        saveAllItems()
    }
    
    func updateItem(_ id: UUID, newText: String) {
        guard let allIdx   = allItems.firstIndex(where: { $0.id == id }),
              let listIdx  = items.firstIndex(where: { $0.id == id }) else { return }
        allItems[allIdx].text = newText
        items[listIdx].text   = newText
        saveAllItems()
    }
    
    func deleteItem(_ id: UUID) {
        allItems.removeAll { $0.id == id }
        items.removeAll    { $0.id == id }
        saveAllItems()
    }
    func deleteItem(at offsets: IndexSet) { offsets.map { items[$0].id }.forEach(deleteItem) }
    func deleteSelected()                 { items.filter(\.isSelected).map(\.id).forEach(deleteItem) }
    
    // --- утилиты
    func getSelectedImages() -> [UIImage] { items.compactMap { $0.isSelected ? $0.image : nil } }
    
    private func saveAllItems() {
        if let encoded = try? JSONEncoder().encode(allItems) {
            UserDefaults.standard.set(encoded, forKey: "qrcodes")
        }
    }
}

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
}


struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]                         // что отдаём в меню
    let activities: [UIActivity]? = nil      // доп-действия (можно оставить nil)

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items,
                                 applicationActivities: activities)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: Context) {}
}




// MARK: - ImageSaver
final class ImageSaver: NSObject {
    private let total: Int
    private let completion: (Int, Int) -> Void
    private var success = 0
    private var error   = 0
    
    init(total: Int, completion: @escaping (Int, Int) -> Void) {
        self.total = total
        self.completion = completion
    }
    
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(done), nil)
    }
    
    @objc private func done(_ image: UIImage,
                            didFinishSavingWithError err: Error?,
                            contextInfo: UnsafeRawPointer) {
        if err == nil { success += 1 } else { error += 1 }
        if success + error == total { completion(success, error) }
    }
}

// MARK: - Строка с QR-кодом
struct QRCodeRow: View {
    let item: QRCodeItem
    @Binding var isSelected: Bool
    var onEdit: () -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                isSelected.toggle()
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    if let image = item.image {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .background(Color.white)
                            .cornerRadius(6)
                            .shadow(radius: 1)
                    }
                    
                    Text(item.text)
                        .font(.body)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                    
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(action: {
                isSelected.toggle()
            }) {
                Label(isSelected ? "Снять выбор" : "Выбрать", systemImage: isSelected ? "circle" : "checkmark.circle")
            }
            
            Button(action: onEdit) {
                Label("Редактировать", systemImage: "pencil")
            }
        }
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
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



#Preview {
    QRCodeGeneratorView()
}
