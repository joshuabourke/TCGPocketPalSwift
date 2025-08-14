//
//  ImageIconView.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 24/7/2025.
//

import Foundation
import SwiftUI
import Combine


// MARK: - Image Types
enum TCGImageType {
    case card(quality: ImageQuality, format: ImageFormat)
    case symbol(format: ImageFormat)
    case logo(format: ImageFormat)
}

// MARK: - Image Quality and Format Options

enum ImageQuality: String {
    case high = "high"
    case low = "low"
}

enum ImageFormat: String {
    case png = "png"
    case jpg = "jpg"
    case webp = "webp"
}

// MARK: - Image URL Builder
struct TCGImageURL {
    let baseURL: String
    let imageType: TCGImageType
    
    init(baseURL: String, imageType: TCGImageType) {
        self.baseURL = baseURL
        self.imageType = imageType
    }
    
    var fullURL: String {
        switch imageType {
        case .card(let quality, let format):
            return "\(baseURL)/\(quality.rawValue).\(format.rawValue)"
        case .symbol(let format), .logo(let format):
            return "\(baseURL).\(format.rawValue)"
        }
    }
}


// MARK: - Image Variants
enum ImageVariant: Equatable {
    case full
    case thumbnail(maxPixel: Int)
}
// MARK: - Image Loading ViewModel
@MainActor
class ImageLoadingViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let imageManager: ImagesManager
    private let tcgImageURL: TCGImageURL
    private let variant: ImageVariant
    
    // For backwards compatibility with direct URLs
    private let directURL: String?
    
    private var finalURL: String {
        return directURL ?? tcgImageURL.fullURL
    }
    
    private var cacheKey: String {
        let baseKey = finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? finalURL
        switch variant {
        case .full:
            return baseKey
        case .thumbnail(let px):
            return "\(baseKey)_thumb_\(px)"
        }
    }
    
    // Primary initializer for TCG images with type-specific options
    init(
        baseURL: String,
        imageType: TCGImageType,
        variant: ImageVariant = .full,
        imageManager: ImagesManager
    ) {
        self.tcgImageURL = TCGImageURL(baseURL: baseURL, imageType: imageType)
        self.directURL = nil
        self.variant = variant
        self.imageManager = imageManager
        loadImage()
    }
    
    // Convenience initializer for cards (backwards compatibility)
    init(
        baseURL: String,
        quality: ImageQuality = .high,
        format: ImageFormat = .png,
        variant: ImageVariant = .full,
        imageManager: ImagesManager
    ) {
        self.tcgImageURL = TCGImageURL(baseURL: baseURL, imageType: .card(quality: quality, format: format))
        self.directURL = nil
        self.variant = variant
        self.imageManager = imageManager
        loadImage()
    }
    
    // Convenience initializer for direct URLs (backwards compatibility)
    init(
        directURL: String,
        variant: ImageVariant = .full,
        imageManager: ImagesManager
    ) {
        self.tcgImageURL = TCGImageURL(baseURL: "", imageType: .card(quality: .high, format: .png)) // Dummy values
        self.directURL = directURL
        self.variant = variant
        self.imageManager = imageManager
        loadImage()
    }
    
    func loadImage() {
        // First check local cache
        if let cachedImage = imageManager.loadImage(for: cacheKey) {
            self.image = cachedImage
            return
        }
        
        // For thumbnails, check if we have the full image cached and downsample it
        if case .thumbnail(let px) = variant {
            let fullImageKey = finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? finalURL
            if let original = imageManager.loadImage(for: fullImageKey) {
                // Use PNG data to preserve transparency, or directly downsample the UIImage
                if let thumb = downsampled(from: original, maxPixel: px) {
                    // Save thumbnail for next time
                    self.imageManager.saveImage(thumb, for: cacheKey)
                    self.image = thumb
                    return
                }
            }
        }
        
        // Otherwise, download from URL
        downloadImage()
    }
    
    private func downloadImage() {
            guard let url = URL(string: finalURL) else {
                print("### Invalid URL string: \(finalURL)")
                self.error = ImageLoadingError.invalidURL
                return
            }
            
            print("📥 Downloading image from: \(finalURL)")
            
            isLoading = true
            error = nil
            
            Task {
                do {
                    let (data, response) = try await URLSession.shared.data(from: url)
                    
                    // Check if the response is valid
                    if let httpResponse = response as? HTTPURLResponse,
                       !(200...299).contains(httpResponse.statusCode) {
                        await MainActor.run {
                            self.isLoading = false
                            self.error = ImageLoadingError.downloadFailed
                        }
                        return
                    }
                    
                    guard let downloadedImage = UIImage(data: data) else {
                        await MainActor.run {
                            self.isLoading = false
                            self.error = ImageLoadingError.invalidImageData
                        }
                        return
                    }
                    
                    await MainActor.run {
                        let final: UIImage
                        switch self.variant {
                        case .full:
                            final = downloadedImage
                        case .thumbnail(let px):
                            // Use the UIImage-based downsampling to preserve transparency
                            final = self.downsampled(from: downloadedImage, maxPixel: px) ?? downloadedImage
                        }
                        
                        self.image = final
                        self.isLoading = false
                        
                        // Save the full-resolution image with URL as key
                        let fullImageKey = self.finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self.finalURL
                        self.imageManager.saveImage(downloadedImage, for: fullImageKey)
                        
                        // Save the variant we're displaying
                        self.imageManager.saveImage(final, for: self.cacheKey)
                    }
                    
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.error = ImageLoadingError.networkError(error)
                        print("### Error downloading image: \(error)")
                    }
                }
            }
        }
    
    private func downsampled(from data: Data, maxPixel: Int) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    // Alternative downsampling method that works directly with UIImage (preserves transparency better)
     private func downsampled(from image: UIImage, maxPixel: Int) -> UIImage? {
         let imageSize = image.size
         let maxDimension = max(imageSize.width, imageSize.height)
         
         // If image is already smaller than maxPixel, return as-is
         if maxDimension <= CGFloat(maxPixel) {
             return image
         }
         
         // Calculate new size maintaining aspect ratio
         let scale = CGFloat(maxPixel) / maxDimension
         let newSize = CGSize(
             width: imageSize.width * scale,
             height: imageSize.height * scale
         )
         
         // Create graphics context with proper format for transparency
         let format = UIGraphicsImageRendererFormat()
         format.scale = 1.0
         format.opaque = false // This is crucial for transparency!
         
         let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
         
         return renderer.image { context in
             image.draw(in: CGRect(origin: .zero, size: newSize))
         }
     }
    
    func retry() {
        error = nil
        loadImage()
    }
}

// MARK: - Image Loading View
struct ImageLoadingView: View {
    @EnvironmentObject var container: DIContainer
    @State private var loader: ImageLoadingViewModel?
    
    let baseURL: String?
    let imageType: TCGImageType
    let variant: ImageVariant
    let placeholder: String
    
    // Primary initializer for TCG images with type specification
    init(
        baseURL: String?,
        imageType: TCGImageType,
        variant: ImageVariant = .full,
        placeholder: String = "photo"
    ) {
        self.baseURL = baseURL
        self.imageType = imageType
        self.variant = variant
        self.placeholder = placeholder
    }
    
    // Convenience initializer for cards (backwards compatibility)
    init(
        baseURL: String?,
        quality: ImageQuality = .high,
        format: ImageFormat = .png,
        variant: ImageVariant = .full,
        placeholder: String = "photo"
    ) {
        self.baseURL = baseURL
        self.imageType = .card(quality: quality, format: format)
        self.variant = variant
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            if baseURL == nil || baseURL?.isEmpty == true {
                Image(systemName: placeholder)
                    .resizable()
                    .foregroundStyle(.orange)
                    .aspectRatio(contentMode: .fit)
            } else if let loader = loader {
                LoaderContentView(loader: loader, placeholder: placeholder)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            setupLoader()
        }
        .onChange(of: baseURL) { oldValue, newBaseURL in
            setupLoader()
        }
    }
    
    private func setupLoader() {
        if let baseURL = baseURL, !baseURL.isEmpty {
            loader = container.makeImageLoadingViewModel(
                baseURL: baseURL,
                imageType: imageType,
                variant: variant
            )
        } else {
            loader = nil
        }
    }
}

// MARK: - Convenience View for Direct URLs
struct DirectImageLoadingView: View {
    @EnvironmentObject var container: DIContainer
    @State private var loader: ImageLoadingViewModel?
    
    let imageURL: String?
    let variant: ImageVariant
    let placeholder: String
    
    init(
        imageURL: String?,
        variant: ImageVariant = .full,
        placeholder: String = "photo"
    ) {
        self.imageURL = imageURL
        self.variant = variant
        self.placeholder = placeholder
    }
    
    var body: some View {
        ZStack {
            if imageURL == nil || imageURL?.isEmpty == true {
                Image(systemName: placeholder)
                    .resizable()
                    .foregroundStyle(.orange)
                    .aspectRatio(contentMode: .fit)
            } else if let loader = loader {
                LoaderContentView(loader: loader, placeholder: placeholder)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            setupLoader()
        }
        .onChange(of: imageURL) { oldValue, newImageURL in
            setupLoader()
        }
    }
    
    private func setupLoader() {
        if let imageURL = imageURL, !imageURL.isEmpty {
            loader = container.makeDirectImageLoadingViewModel(
                imageURL: imageURL,
                variant: variant
            )
        } else {
            loader = nil
        }
    }
}

// MARK: - Loader Content View
struct LoaderContentView: View {
    @ObservedObject var loader: ImageLoadingViewModel
    let placeholder: String
    
    var body: some View {
        if loader.isLoading {
            ProgressView()
        } else if loader.error != nil {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text("Failed to load")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Retry") {
                    loader.retry()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        } else if let image = loader.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: placeholder)
                .resizable()
                .foregroundStyle(.gray)
                .aspectRatio(contentMode: .fit)
        }
    }
}

