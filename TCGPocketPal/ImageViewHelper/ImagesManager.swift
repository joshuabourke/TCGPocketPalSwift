//
//  PhotoModelFileManager.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 29/5/2025.
//

import Foundation
import SwiftUI

enum ImageFileFormat {
    case png
    case jpeg(compressionQuality: CGFloat)
}


@MainActor
class ImagesManager: ObservableObject {
    static let shared = ImagesManager() // Keep for backward compatibility if needed
    
    private let folderName = "downloaded_photos"

    init() {
        createFolderIfNeeded()
    }
    
    // MARK: - Folder Management
    private func createFolderIfNeeded() {
        guard let url = getFolderPath() else { return }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("### Created Image Folder at: \(url)")
            } catch {
                print("### Error creating folder: \(error)")
            }
        }
    }
    
    private func getFolderPath() -> URL? {
        return FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(folderName)
    }
    
    private func getImagePath(for key: String) -> URL? {
        guard let folder = getFolderPath() else { return nil }
        return folder.appendingPathComponent(key + ".jpg")
    }
    
    // MARK: - Image Storage Operations
    func saveImage(_ image: UIImage, for key: String) {
        guard
            let data = image.pngData(),
            let url = getImagePath(for: key)
        else {
            print("### Failed to save image for key: \(key)")
            return
        }
        
        do {
            try data.write(to: url)
            print("### Image saved successfully for key: \(key)")
        } catch {
            print("### Error saving image for key \(key): \(error)")
        }
    }
    
    func saveImage(_ image: UIImage, for id: UUID) {
        saveImage(image, for: id.uuidString)
    }
    
    func loadImage(for key: String) -> UIImage? {
        guard
            let url = getImagePath(for: key),
            FileManager.default.fileExists(atPath: url.path)
        else {
            return nil
        }
        return UIImage(contentsOfFile: url.path)
    }
    
    func loadImage(for id: UUID) -> UIImage? {
        return loadImage(for: id.uuidString)
    }
    
    func imageExists(for key: String) -> Bool {
        guard let url = getImagePath(for: key) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    func imageExists(for id: UUID) -> Bool {
        return imageExists(for: id.uuidString)
    }
    
    // MARK: - Cleanup Operations
    func removeImage(for key: String) {
        guard let url = getImagePath(for: key) else { return }
        
        do {
            try FileManager.default.removeItem(at: url)
            print("### Image removed for key: \(key)")
        } catch {
            print("### Error removing image for key \(key): \(error)")
        }
    }
    
    func removeImage(for id: UUID) {
        removeImage(for: id.uuidString)
    }
    
    func removeAllImages() {
        guard let folderPath = getFolderPath() else {
            print("### Error: Folder path not found.")
            return
        }
        
        do {
            let fileManager = FileManager.default
            let files = try fileManager.contentsOfDirectory(
                at: folderPath,
                includingPropertiesForKeys: nil,
                options: []
            )
            
            for file in files {
                try fileManager.removeItem(at: file)
            }
            print("### All images removed successfully.")
        } catch {
            print("### Error removing images: \(error)")
        }
    }
    
}
