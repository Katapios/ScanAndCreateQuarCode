//
//  ImageSaver.swift
//  ScanAndCreateQuarCode
//
//  Created by Денис Рюмин on 01.07.2025.
//

import PhotosUI
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
