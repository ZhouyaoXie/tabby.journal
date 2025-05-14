import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.garamondBold(size: 24))
                    .padding()
                
                Spacer()
                
                Text("Settings options will go here")
                    .font(.garamond(size: 16))
                    .foregroundColor(.gray)
                
                Spacer()
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
} 