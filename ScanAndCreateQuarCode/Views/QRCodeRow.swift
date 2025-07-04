//
//  QRCodeRow.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

struct QRCodeRow: View {
    let item: QRCodeItem
    @Binding var isSelected: Bool
    var onEdit: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            Button { isSelected.toggle() } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
            }
            .buttonStyle(.plain)

            if let image = item.image {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .background(Color.white)
                    .cornerRadius(6)
                    .shadow(radius: 1)
                    .drawingGroup()
            }

            Text(item.text)
                .lineLimit(2)
                .padding(.vertical, 8)

            Spacer(minLength: 0)

            Button(action: { onEdit() }) {
                Image(systemName: "pencil")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 20)
        .contextMenu {
            Button { isSelected.toggle() } label: {
                Label(isSelected ? "Снять выбор" : "Выбрать",
                      systemImage: isSelected ? "circle" : "checkmark.circle")
            }
            Button(action: onEdit) {
                Label("Редактировать", systemImage: "pencil")
            }
        }
        .background(isSelected ? Color.blue.opacity(0.1) : .clear)
        .cornerRadius(8)
    }
}
