//
//  QRCodeStore.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import Foundation
import SwiftUI

@MainActor
final class QRCodeStore: ObservableObject {
    @Published private(set) var all: [QRCodeItem] = []
    @Published private(set) var visibleCount = 0           // ленивый скролл
    private let batch = 15
    private let key = "qrcodes"

    // cрез, который реально отображается
    var items: [QRCodeItem] { Array(all.prefix(visibleCount)) }

    init() { Task { await loadAll() } }

    // MARK: – Публичные методы ------------------------------------------------
    func loadMore() {
        guard visibleCount < all.count else { return }
        visibleCount = min(visibleCount + batch, all.count)
    }

    func addItem(text: String, image: UIImage) {
        let path = saveImageToDisk(image)
        let new = QRCodeItem(text: text, imagePath: path)
        all.insert(new, at: 0)
            // делаем новый элемент видимым
            if visibleCount < batch {
                visibleCount += 1          // пока не заполнили первую страницу
            }
        save()
    }

    func updateItem(_ id: UUID, newText: String) {
        if let index = all.firstIndex(where: { $0.id == id }) {
            all[index].text = newText
            save()
        }
    }

    func deleteItem(_ id: UUID) {
        all.removeAll { $0.id == id }
        save()
    }
    func deleteItem(at offsets: IndexSet) {
        offsets.map { items[$0].id }.forEach(deleteItem)
    }
    func deleteSelected() {
        items.filter(\.isSelected).map(\.id).forEach(deleteItem)
    }

    // выбор
    func setSelected(_ isSelected: Bool, forId id: UUID) {
        if let idx = all.firstIndex(where: { $0.id == id }) {
            all[idx].isSelected = isSelected
        }
    }
    func selectAll()   { all.indices.forEach { all[$0].isSelected = true  } }
    func deselectAll() { all.indices.forEach { all[$0].isSelected = false } }

    func getSelectedImages() -> [UIImage] {
        items.compactMap { $0.isSelected ? $0.image : nil }
    }

    // MARK: – Private ---------------------------------------------------------
    private func loadAll() async {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([QRCodeItem].self, from: data) {
            all = decoded.sorted { $0.text < $1.text }
        }
        loadMore()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    private func saveImageToDisk(_ image: UIImage) -> String? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0]
            .appendingPathComponent(UUID().uuidString + ".png")
        try? data.write(to: url, options: .atomic)
        return url.path
    }
}

// расширяем под протокол редактирования
extension QRCodeStore: QRItemUpdatable {
    func update(_ id: UUID, newText: String) { updateItem(id, newText: newText) }
}
