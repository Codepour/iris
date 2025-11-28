import SwiftUI

struct DistributionConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var selectedVariables: Set<String> = []
    
    // Percentiles
    @State private var calculatePercentiles: Bool = true
    @State private var percentileString: String = "5, 10, 25, 50, 75, 90, 95"
    
    // Z-Scores
    @State private var showOutliers: Bool = true
    
    // Frequencies
    @State private var showFrequencies: Bool = true
    @State private var bins: Int = 10
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Distribution Analysis")
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
                                }
                            }
                        }
                        .frame(minHeight: 150)
                        .border(Color.gray.opacity(0.2))
                    }
                    
                    // Percentiles
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Percentiles", isOn: $calculatePercentiles)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if calculatePercentiles {
                            TextField("e.g. 5, 25, 50, 75, 95", text: $percentileString)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                        }
                    }
                    
                    Divider()
                    
                    // Z-Scores
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Z-Scores")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Toggle("Show Outliers (Z > 3)", isOn: $showOutliers)
                    }
                    
                    Divider()
                    
                    // Frequencies
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Frequency Distribution", isOn: $showFrequencies)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if showFrequencies {
                            Stepper("Bins: \(bins)", value: $bins, in: 2...100)
                        }
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
                .disabled(selectedVariables.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
    }
    
    private func runAnalysis() {
        // Parse percentiles
        let percentiles = percentileString
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            .map { $0 / 100.0 } // Convert 50 -> 0.5
        
        let sortedVars = dataFrame.headers.filter { selectedVariables.contains($0) }
        
        dataFrame.runDistributionAnalysis(
            variables: sortedVars,
            percentiles: calculatePercentiles ? percentiles : [],
            showOutliers: showOutliers,
            showFrequencies: showFrequencies,
            bins: bins
        )
    }
}
