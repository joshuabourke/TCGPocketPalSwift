//
//  ImageLoadingError.swift
//  TCGPocketPal
//
//  Created by Josh Bourke on 24/7/2025.
//

import Foundation


// MARK: - Image Loading Errors
enum ImageLoadingError: Error, LocalizedError {
    case invalidURL
    case invalidImageData
    case networkError(Error)
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidImageData:
            return "Invalid image data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .downloadFailed:
            return "Download failed"
        }
    }
}
