import SwiftUI

// This file serves as documentation of the view structure
// and contains shared view extensions or utilities

// Shared extensions for view styling
extension View {
    func standardCardStyle() -> some View {
        self
            .padding(14)
            .background(Color("CardBackground"))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
} 