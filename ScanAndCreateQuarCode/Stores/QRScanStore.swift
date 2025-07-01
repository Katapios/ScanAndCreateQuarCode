//
//  QRScanStore.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import Foundation
import SwiftUI

@MainActor
final class QRScanStore: ObservableObject {
    @Published private(set) var all: [QRCodeItem] = []
    @Published private(set) var visible = 0
    private let batch = 15
    private let key = "qrscans"

    var items: [QRCodeItem] { Array(all.prefix(visible)) }

    init() { Task { await load() } }

    // MARK: – CRUD ------------------------------------------------------------
    func add(text: String, image: UIImage?) {
        guard !text.isEmpty else { return }
        let path = image.flatMap(saveImageToDisk)
        let item = QRCodeItem(text: text, imagePath: path)
        all.insert(item, at: 0)
        
            // ⚠️ делаем новый элемент видимым
            if visible < batch {
                visible += 1                // пока скролл не заполнил batch
            } else {
                // если уже показываем batch-страницу, пусть число остаётся,
                // а новый элемент вытеснит самый старый за пределы prefix
            }
        save()
    }

    func delete(_ id: UUID) {
        all.removeAll { $0.id == id }
        save()
    }
    func delete(at offsets: IndexSet) { offsets.map { items[$0].id }.forEach(delete) }
    func deleteSelected() { items.filter(\.isSelected).map(\.id).forEach(delete) }

    func update(_ id: UUID, text: String) {
        if let idx = all.firstIndex(where: { $0.id == id }) {
            all[idx].text = text
            save()
        }
    }

    // выбор
    func set(_ id: UUID, selected: Bool) {
        if let idx = all.firstIndex(where: { $0.id == id }) {
            all[idx].isSelected = selected
        }
    }
    func selectAll()   { all.indices.forEach { all[$0].isSelected = true  } }
    func deselectAll() { all.indices.forEach { all[$0].isSelected = false } }
    func selectedImages() -> [UIImage] { items.compactMap { $0.isSelected ? $0.image : nil } }

    // MARK: – Пагинация -------------------------------------------------------
    func loadMore() {
        guard visible < all.count else { return }
        visible = min(visible + batch, all.count)
    }

    // MARK: – Persistence -----------------------------------------------------
    private func load() async {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([QRCodeItem].self, from: data) {
            all = decoded
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

extension QRScanStore: QRItemUpdatable {
    func update(_ id: UUID, newText: String) { update(id, text: newText) }
}
