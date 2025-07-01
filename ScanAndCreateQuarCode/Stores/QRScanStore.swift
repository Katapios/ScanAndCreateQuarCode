//
//  QRScanStore.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

final class QRScanStore: ObservableObject {
    @Published private(set) var items: [QRCodeItem] = []
    
    private var all: [QRCodeItem] = []
    private let batch = 15
    private var loaded = 0
    
    init() {
        loadAll()
        loadMore()
    }
    
    // MARK: – CRUD
    func add(text: String, image: UIImage?) {
        guard !text.isEmpty else { return }
        let item = QRCodeItem(text: text,
                              imageData: image?.pngData())
        all.insert(item, at: 0)
        items.insert(item, at: 0)
        loaded += 1
        save()
    }
    func delete(_ id: UUID) {
        all.removeAll { $0.id == id }
        items.removeAll { $0.id == id }
        save()
    }
    func delete(at offsets: IndexSet) { offsets.map { items[$0].id }.forEach(delete) }
    func deleteSelected() { items.filter(\.isSelected).map(\.id).forEach(delete) }
    func update(_ id: UUID, text: String) {
        guard let ai = all.firstIndex(where: { $0.id == id }),
              let ii = items.firstIndex(where: { $0.id == id }) else { return }
        all[ai].text = text
        items[ii].text = text
        save()
    }
    
    // выбор
    func set(_ id: UUID, selected: Bool) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isSelected = selected
    }
    func selectAll()   { items.indices.forEach { items[$0].isSelected = true  } }
    func deselectAll() { items.indices.forEach { items[$0].isSelected = false } }
    func selectedImages() -> [UIImage] { items.compactMap { $0.isSelected ? $0.image : nil } }
    
    // ленивый скролл
    func loadMore() {
        guard loaded < all.count else { return }
        let next = all[loaded..<min(loaded + batch, all.count)]
        items.append(contentsOf: next)
        loaded += next.count
    }
    
    // MARK: – Persistence
    private let key = "qrscans"
    private func loadAll() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([QRCodeItem].self, from: data) {
            all = decoded
        }
    }
    private func save() {
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}

