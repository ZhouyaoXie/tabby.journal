import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.title)
                    .padding()
                
                Spacer()
                
                Text("Settings options will go here")
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