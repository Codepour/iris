import SwiftUI

struct PartialCorrelationConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var selectedVariables: Set<String> = []
    @State private var selectedControls: Set<String> = []
    @State private var significanceTest: StatisticsEngine.SignificanceTestType = .twoTailed
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Partial Correlation")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Variables List
                    VStack(alignment: .leading) {
                        Text("Variables")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        List(dataFrame.headers, id: \.self) { header in
                            HStack {
                                Text(header)
                                Spacer()
                                if selectedVariables.contains(header) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedVariables.contains(header) {
                                    selectedVariables.remove(header)
                                } else {
                                    selectedVariables.insert(header)
                                    // Remove from controls if present
                                    selectedControls.remove(header)
                                }
                            }
                        }
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    // Controls List
                    VStack(alignment: .leading) {
                        Text("Controlling for")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        List(dataFrame.headers, id: \.self) { header in
                            HStack {
                                Text(header)
                                Spacer()
                                if selectedControls.contains(header) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.orange)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedControls.contains(header) {
                                    selectedControls.remove(header)
                                } else {
                                    selectedControls.insert(header)
                                    // Remove from variables if present
                                    selectedVariables.remove(header)
                                }
                            }
                        }
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test of Significance")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Test Type", selection: $significanceTest) {
                            Text("Two-tailed").tag(StatisticsEngine.SignificanceTestType.twoTailed)
                            Text("One-tailed").tag(StatisticsEngine.SignificanceTestType.oneTailed)
                        }
                        .pickerStyle(.radioGroup)
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
                
                Button("OK") {
                    runAnalysis()
                    onRun()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedVariables.count < 2 || selectedControls.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
    }
    
    private func runAnalysis() {
        let vars = dataFrame.headers.filter { selectedVariables.contains($0) }
        let controls = dataFrame.headers.filter { selectedControls.contains($0) }
        
        dataFrame.runPartialCorrelation(variables: vars, controls: controls, testType: significanceTest)
    }
}
