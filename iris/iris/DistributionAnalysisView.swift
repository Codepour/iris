import SwiftUI

struct DistributionAnalysisView: View {
    let distributions: [DataFrame.DistributionResult]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Distribution Analysis")
                    .font(.system(.headline, design: .serif).bold())
                    .padding(.horizontal)
                
                ForEach(distributions, id: \.variable) { result in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(result.variable)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // Percentiles
                        if !result.percentiles.isEmpty {
                            PercentilesView(result: result)
                        }
                        
                        // Frequencies
                        if let freq = result.frequencies {
                            FrequencyDistributionView(result: result, freq: freq)
                        }
                        
                        // Outliers
                        if !result.zScoreOutliers.isEmpty {
                            OutliersView(result: result)
                        }
                        
                        Divider()
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct PercentilesView: View {
    let result: DataFrame.DistributionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Percentiles")
                .font(.system(.subheadline, design: .serif).bold())
                .padding(.horizontal)

            let sortedKeys = result.percentiles.keys.sorted()

            VStack(spacing: 0) {
                // Top border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)

                // Header
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 150, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.leading, 12)

                    VStack(alignment: .center, spacing: 2) {
                        Text("Percentiles")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Column headers
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 150, alignment: .leading)
                        .padding(.vertical, 6)
                        .padding(.leading, 12)

                    ForEach(sortedKeys, id: \.self) { key in
                        Text("\(Int(key * 100))")
                            .font(.caption)
                            .fontWeight(.regular)
                            .frame(minWidth: 80, alignment: .trailing)
                            .padding(.trailing, 12)
                    }
                }
                .background(Color.clear)

                // Header bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)

                // Data row
                HStack(spacing: 0) {
                    Text(result.variable)
                        .fontWeight(.regular)
                        .frame(width: 150, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.leading, 12)

                    ForEach(sortedKeys, id: \.self) { key in
                        Text(String(format: "%.3f", result.percentiles[key] ?? 0))
                            .font(.system(.body, design: .default))
                            .frame(minWidth: 80, alignment: .trailing)
                            .padding(.trailing, 12)
                    }
                }
                .background(Color.clear)

                // Bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)
            }
            .padding(.horizontal)
        }
    }
}

struct FrequencyDistributionView: View {
    let result: DataFrame.DistributionResult
    let freq: (counts: [Int], binEdges: [Double])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency Distribution")
                .font(.system(.subheadline, design: .serif).bold())
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Top border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)

                // Header
                HStack(spacing: 0) {
                    Text("Range")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                        .padding(.vertical, 8)
                    Text("Count")
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .trailing)
                        .padding(.trailing, 12)
                        .padding(.vertical, 8)
                }
                .background(Color.gray.opacity(0.05))

                // Header bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)
                
                ForEach(0..<freq.counts.count, id: \.self) { i in
                    let lower = freq.binEdges[i]
                    let upper = freq.binEdges[i+1]
                    HStack(spacing: 0) {
                        Text("\(String(format: "%.2f", lower)) - \(String(format: "%.2f", upper))")
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 12)
                            .padding(.vertical, 6)
                        
                        Text("\(freq.counts[i])")
                            .frame(width: 80, alignment: .trailing)
                            .padding(.trailing, 12)
                            .padding(.vertical, 6)
                    }
                    .background(i % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
                }

                // Bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)
            }
            .padding(.horizontal)
            
            // Chart
            HistogramChart(
                binEdges: freq.binEdges,
                counts: freq.counts,
                color: .blue.opacity(0.7),
                xAxisLabel: result.variable
            )
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
}

struct OutliersView: View {
    let result: DataFrame.DistributionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Outliers (Z > 3)")
                .font(.system(.subheadline, design: .serif).bold())
                .foregroundColor(.red)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Top border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)

                // Header
                HStack(spacing: 0) {
                    Text("Row")
                        .fontWeight(.semibold)
                        .frame(width: 80, alignment: .leading)
                        .padding(.leading, 12)
                        .padding(.vertical, 8)
                    Text("Value")
                        .fontWeight(.semibold)
                        .frame(width: 100, alignment: .trailing)
                        .padding(.vertical, 8)
                    Text("Z-Score")
                        .fontWeight(.semibold)
                        .frame(width: 100, alignment: .trailing)
                        .padding(.trailing, 12)
                        .padding(.vertical, 8)
                    Spacer()
                }
                .background(Color.gray.opacity(0.05))

                // Header bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)

                ForEach(Array(result.zScoreOutliers.enumerated()), id: \.element.row) { index, outlier in
                    HStack(spacing: 0) {
                        Text("\(outlier.row + 1)")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                            .padding(.leading, 12)
                            .padding(.vertical, 6)
                        
                        Text(String(format: "%.4f", outlier.value))
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.vertical, 6)
                        
                        Text(String(format: "%.2f", outlier.z))
                            .foregroundColor(abs(outlier.z) > 4 ? .red : .primary)
                            .frame(width: 100, alignment: .trailing)
                            .padding(.trailing, 12)
                            .padding(.vertical, 6)
                        
                        Spacer()
                    }
                    .background(index % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
                }

                // Bottom border
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1.5)
            }
            .padding(.horizontal)
        }
    }
}
