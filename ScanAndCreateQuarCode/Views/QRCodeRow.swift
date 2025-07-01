//
//  QRCodeRow.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

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
