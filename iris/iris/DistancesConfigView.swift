import SwiftUI

struct DistancesConfigView: View {
    @ObservedObject var dataFrame: DataFrame
    var onRun: () -> Void
    var onCancel: () -> Void
    
    @State private var selectedVariables: Set<String> = []
    @State private var distanceMetric: StatisticsEngine.DistanceMetric = .euclidean
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Distances")
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
            
            // Options
            VStack(alignment: .leading, spacing: 12) {
                Text("Measure")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Metric", selection: $distanceMetric) {
                    Text("Euclidean").tag(StatisticsEngine.DistanceMetric.euclidean)
                    Text("Squared Euclidean").tag(StatisticsEngine.DistanceMetric.squaredEuclidean)
                    Text("Manhattan").tag(StatisticsEngine.DistanceMetric.manhattan)
                    Text("Chebyshev").tag(StatisticsEngine.DistanceMetric.chebyshev)
                }
                .pickerStyle(.radioGroup)
            }
            
            Spacer()
            
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
                .disabled(selectedVariables.count < 2)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func runAnalysis() {
        let vars = dataFrame.headers.filter { selectedVariables.contains($0) }
        dataFrame.runDistances(variables: vars, metric: distanceMetric)
    }
}
