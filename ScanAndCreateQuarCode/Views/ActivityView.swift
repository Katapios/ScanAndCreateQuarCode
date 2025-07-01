//
//  ActivityView.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import SwiftUI

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
