//
//  QRCodeStore.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

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
