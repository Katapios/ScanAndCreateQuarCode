//
//  EditQRItemView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

/// Редактор текста QR-элемента, работает с любым Store,
/// который является ObservableObject **и** реализует QRItemUpdatable.
struct EditQRItemView<Store>: View where Store: ObservableObject & QRItemUpdatable {
    @Environment(\.dismiss) private var dismiss
    
    let item: QRCodeItem
    @ObservedObject var store: Store             // <- теперь проходит проверку
    
    @State private var editedText: String
    
    init(item: QRCodeItem, store: Store) {
        self.item = item
        self.store = store
        _editedText = State(initialValue: item.text)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Текст", text: $editedText)
                }
                Section {
                    if let shot = item.image {
                        Image(uiImage: shot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                }
                Section {
                    Button("Сохранить изменения") {
                        store.update(item.id, newText: editedText)
                        dismiss()
                    }
                    .disabled(editedText.trimmingCharacters(in: .whitespaces).isEmpty ||
                              editedText == item.text)
                }
            }
            .navigationTitle("Редактировать QR-код")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}
