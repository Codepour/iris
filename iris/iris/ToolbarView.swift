import SwiftUI
import UniformTypeIdentifiers

struct ToolbarView: View {
    @ObservedObject var dataFrame: DataFrame
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {}) {
                Label("Save", systemImage: "square.and.arrow.down")
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .border(Color.gray.opacity(0.2), width: 1)
    }
}
