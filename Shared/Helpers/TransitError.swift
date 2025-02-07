import SwiftUI

enum TransitError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case invalidData
    case serviceDown
    case parseError(String)
    case batchProcessingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .serviceDown:
            return "Transit service is currently unavailable"
        case .parseError(let message):
            return "Data parsing error: \(message)"
        case .batchProcessingError(let message):
            return "Error processing stops: \(message)"
        }
    }
}
