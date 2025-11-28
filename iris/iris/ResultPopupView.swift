import SwiftUI

/// A popup view that displays analysis results and allows adding them to the output collection
struct ResultPopupView<Content: View>: View {
    let title: String
    let content: Content
    let onAddToOutput: () -> Void
    let onDismiss: () -> Void
    
    init(
        title: String,
        @ViewBuilder content: () -> Content,
        onAddToOutput: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.content = content()
        self.onAddToOutput = onAddToOutput
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content - bidirectional scroll for wide tables
            ScrollView([.horizontal, .vertical]) {
                content
                    .padding()
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer
            HStack {
                Button("Close") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add to Output") {
                    onAddToOutput()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: OutputSizing.resultPopupWidth, maxWidth: 1200)
        .frame(minHeight: OutputSizing.resultPopupMinHeight, maxHeight: OutputSizing.resultPopupMaxHeight)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// A generic container for config popup views
struct ConfigPopupContainer<Content: View>: View {
    let title: String
    let content: Content
    let onRun: () -> Void
    let onCancel: () -> Void
    let isRunDisabled: Bool
    
    init(
        title: String,
        isRunDisabled: Bool = false,
        @ViewBuilder content: () -> Content,
        onRun: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.content = content()
        self.onRun = onRun
        self.onCancel = onCancel
        self.isRunDisabled = isRunDisabled
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                content
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("OK") {
                    onRun()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isRunDisabled)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
