import SwiftUI

struct CorrelationConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var selectedVariables: Set<String> = []
    @State private var correlationMethod: StatisticsEngine.CorrelationMethod = .pearson
    @State private var flagSignificant: Bool = true
    
    @State private var missingValues: DataFrame.MissingValueStrategy = .listwise
    @State private var significanceTest: StatisticsEngine.SignificanceTestType = .twoTailed
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bivariate Correlations")
                    .font(.headline)
                Spacer()
            }
            
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Coefficients
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Coefficients")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Method", selection: $correlationMethod) {
                            Text("Pearson").tag(StatisticsEngine.CorrelationMethod.pearson)
                            Text("Spearman").tag(StatisticsEngine.CorrelationMethod.spearman)
                        }
                        .pickerStyle(.radioGroup)
                    }
                    
                    Divider()
                    
                    // Significance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Test of Significance")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Test Type", selection: $significanceTest) {
                            Text("Two-tailed").tag(StatisticsEngine.SignificanceTestType.twoTailed)
                            Text("One-tailed").tag(StatisticsEngine.SignificanceTestType.oneTailed)
                        }
                        .pickerStyle(.radioGroup)
                        
                        Toggle("Flag significant", isOn: $flagSignificant)
                    }
                    
                    Divider()
                    
                    // Missing Values
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Missing Values")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Missing Values", selection: $missingValues) {
                            Text("Exclude cases listwise").tag(DataFrame.MissingValueStrategy.listwise)
                            Text("Exclude cases pairwise").tag(DataFrame.MissingValueStrategy.pairwise)
                        }
                        .pickerStyle(.radioGroup)
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("OK") {
                    runCorrelation()
                    onRun()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedVariables.count < 2)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func runCorrelation() {
        // Sort variables to match header order
        let sortedVars = dataFrame.headers.filter { selectedVariables.contains($0) }
        dataFrame.runCorrelation(variables: sortedVars, method: correlationMethod, missingStrategy: missingValues, testType: significanceTest)
    }
}
