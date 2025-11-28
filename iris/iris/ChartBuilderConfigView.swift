import SwiftUI

struct ChartBuilderConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var xVariable: String = ""
    @State private var yVariable: String = ""
    @State private var chartTitle: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chart Builder")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Variables
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variables")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("X Axis", selection: $xVariable) {
                            Text("Select Variable").tag("")
                            ForEach(dataFrame.headers, id: \.self) { header in
                                Text(header).tag(header)
                            }
                        }
                        
                        Picker("Y Axis", selection: $yVariable) {
                            Text("Select Variable").tag("")
                            ForEach(dataFrame.headers, id: \.self) { header in
                                Text(header).tag(header)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Settings
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Chart Title", text: $chartTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Create Chart") {
                    runChart()
                    onRun()
                }
                .buttonStyle(.borderedProminent)
                .disabled(xVariable.isEmpty || yVariable.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
    }
    
    private func runChart() {
        dataFrame.runScatterPlot(x: xVariable, y: yVariable, title: chartTitle)
    }
}
