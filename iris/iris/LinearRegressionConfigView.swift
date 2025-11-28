import SwiftUI

struct LinearRegressionConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var dependentVariable: String?
    @State private var independentVariables: Set<String> = []
    
    // Statistics
    @State private var showEstimates: Bool = true
    @State private var showModelFit: Bool = true
    @State private var showConfidenceIntervals: Bool = false
    @State private var showResiduals: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Linear Regression")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Dependent Variable (Single Selection)
                    VStack(alignment: .leading) {
                        Text("Dependent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        List(dataFrame.headers, id: \.self) { header in
                            HStack {
                                Text(header)
                                Spacer()
                                if dependentVariable == header {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                dependentVariable = header
                                // Remove from independents if present
                                if independentVariables.contains(header) {
                                    independentVariables.remove(header)
                                }
                            }
                        }
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    // Independent Variables (Multi Selection)
                    VStack(alignment: .leading) {
                        Text("Independent(s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        List(dataFrame.headers, id: \.self) { header in
                            HStack {
                                Text(header)
                                Spacer()
                                if independentVariables.contains(header) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if independentVariables.contains(header) {
                                    independentVariables.remove(header)
                                } else {
                                    independentVariables.insert(header)
                                    // Remove from dependent if present
                                    if dependentVariable == header {
                                        dependentVariable = nil
                                    }
                                }
                            }
                        }
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    // Statistics
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Statistics")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Toggle("Estimates", isOn: $showEstimates)
                        Toggle("Model fit", isOn: $showModelFit)
                        Toggle("Confidence intervals", isOn: $showConfidenceIntervals)
                        Toggle("Residuals", isOn: $showResiduals)
                    }
                    
                    Divider()
                    
                    Button("Plots...") {
                        // Placeholder for plots sheet
                    }
                    .disabled(true) // Future implementation
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
                .disabled(dependentVariable == nil || independentVariables.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
    }
    
    private func runAnalysis() {
        guard let dependent = dependentVariable else { return }
        let independents = dataFrame.headers.filter { independentVariables.contains($0) }
        
        let options = DataFrame.LinearRegressionOptions(
            showEstimates: showEstimates,
            showModelFit: showModelFit,
            showConfidenceIntervals: showConfidenceIntervals,
            showResiduals: showResiduals
        )
        
        dataFrame.runLinearRegression(dependent: dependent, independents: independents, options: options)
    }
}
