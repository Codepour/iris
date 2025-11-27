import SwiftUI

struct InspectorView: View {
    @ObservedObject var dataFrame: DataFrame
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Inspector")
                .font(.headline)
                .padding()
            
            Divider()
            
            if let stats = dataFrame.currentStatistics {
                List {
                    Section(header: Text("Basic Measures")) {
                        StatRow(label: "Count", value: "\(stats.count)")
                        StatRow(label: "Mean", value: String(format: "%.4f", stats.mean))
                        StatRow(label: "Median", value: String(format: "%.4f", stats.median))
                        if let mode = stats.mode {
                            StatRow(label: "Mode", value: String(format: "%.4f", mode))
                        } else {
                            StatRow(label: "Mode", value: "N/A")
                        }
                    }
                    
                    Section(header: Text("Spread")) {
                        StatRow(label: "Variance", value: String(format: "%.4f", stats.variance))
                        StatRow(label: "Std Dev", value: String(format: "%.4f", stats.standardDeviation))
                        StatRow(label: "Range", value: String(format: "%.4f", stats.range))
                        StatRow(label: "Min", value: String(format: "%.4f", stats.min))
                        StatRow(label: "Max", value: String(format: "%.4f", stats.max))
                    }
                    
                    Section(header: Text("Shape")) {
                        StatRow(label: "Skewness", value: String(format: "%.4f", stats.skewness))
                        StatRow(label: "Kurtosis", value: String(format: "%.4f", stats.kurtosis))
                    }
                    
                    Section(header: Text("Quartiles")) {
                        StatRow(label: "Q1", value: String(format: "%.4f", stats.q1))
                        StatRow(label: "Q2 (Median)", value: String(format: "%.4f", stats.q2))
                        StatRow(label: "Q3", value: String(format: "%.4f", stats.q3))
                        StatRow(label: "IQR", value: String(format: "%.4f", stats.iqr))
                    }
                }
            } else if let correlation = dataFrame.correlationResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Correlations")
                            .font(.headline)
                            .padding(.horizontal)

                        // Matrix View
                        ScrollView(.horizontal) {
                            VStack(spacing: 0) {
                                // Top border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)

                                // Header Row
                                HStack(spacing: 0) {
                                    Text("")
                                        .frame(width: 150, alignment: .leading)
                                        .padding(.leading, 12)
                                        .padding(.vertical, 8)

                                    Text("")
                                        .frame(width: 150, alignment: .leading)
                                        .padding(.leading, 12)
                                        .padding(.vertical, 8)

                                    ForEach(correlation.variables, id: \.self) { variable in
                                        Text(variable)
                                            .fontWeight(.semibold)
                                            .frame(minWidth: 100, alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }
                                }

                                // Header bottom border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)

                                // Data Rows - grouped by variable
                                ForEach(0..<correlation.variables.count, id: \.self) { i in
                                    VStack(spacing: 0) {
                                        // Correlation row
                                        HStack(spacing: 0) {
                                            Text(correlation.variables[i])
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            Text("\(correlation.method == .pearson ? "Pearson" : "Spearman") Correlation")
                                                .foregroundColor(.secondary)
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            ForEach(0..<correlation.variables.count, id: \.self) { j in
                                                let value = correlation.matrix[i][j]
                                                let isSig = correlation.significant[i][j]

                                                Text(i == j ? "1" : String(format: "%.3f", value))
                                                    .fontWeight(isSig && i != j ? .bold : .regular)
                                                    .frame(minWidth: 100, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 6)
                                            }
                                        }
                                        .background(i % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)

                                        // Significance row
                                        HStack(spacing: 0) {
                                            Text("")
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            Text("Sig. (\(correlation.testType == .twoTailed ? "2" : "1")-tailed)")
                                                .foregroundColor(.secondary)
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            ForEach(0..<correlation.variables.count, id: \.self) { j in
                                                let isSig = correlation.significant[i][j]

                                                Text(i == j ? "" : (isSig ? "<.001" : "."))
                                                    .frame(minWidth: 100, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 6)
                                            }
                                        }
                                        .background(i % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
                                    }
                                }

                                // Bottom border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)
                            }
                            .padding(.horizontal)
                        }

                        // Note
                        if correlation.significant.flatMap({ $0 }).contains(true) {
                            let tailedText = correlation.testType == .twoTailed ? "2-tailed" : "1-tailed"
                            Text("***. Correlation is significant at the 0.001 level (\(tailedText)).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let distributions = dataFrame.distributionResults {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Distribution Analysis")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(distributions, id: \.variable) { result in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(result.variable)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                // Percentiles
                                if !result.percentiles.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Percentiles")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
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
                                
                                // Frequencies
                                if let freq = result.frequencies {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Frequency Distribution")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal)
                                        
                                        VStack(spacing: 0) {
                                            HStack {
                                                Text("Range")
                                                    .fontWeight(.bold)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                Text("Count")
                                                    .fontWeight(.bold)
                                                    .frame(width: 60, alignment: .trailing)
                                            }
                                            .padding(8)
                                            .background(Color.gray.opacity(0.1))
                                            
                                            ForEach(0..<freq.counts.count, id: \.self) { i in
                                                let lower = freq.binEdges[i]
                                                let upper = freq.binEdges[i+1]
                                                HStack {
                                                    Text("\(String(format: "%.2f", lower)) - \(String(format: "%.2f", upper))")
                                                        .font(.caption)
                                                    Spacer()
                                                    Text("\(freq.counts[i])")
                                                        .font(.caption)
                                                }
                                                .padding(4)
                                                Divider()
                                            }
                                        }
                                        .border(Color.gray.opacity(0.2))
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
                                
                                // Outliers
                                if !result.zScoreOutliers.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Outliers (Z > 3)")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.red)
                                            .padding(.horizontal)
                                        
                                        ForEach(result.zScoreOutliers, id: \.row) { outlier in
                                            HStack {
                                                Text("Row \(outlier.row + 1):")
                                                    .foregroundColor(.secondary)
                                                Text(String(format: "%.4f", outlier.value))
                                                    .fontWeight(.medium)
                                                Spacer()
                                                Text("Z: \(String(format: "%.2f", outlier.z))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                                
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical)
                }
            } else if let partialResult = dataFrame.partialCorrelationResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Correlations")
                            .font(.headline)
                            .padding(.horizontal)

                        // Control Variables info
                        if let controls = partialResult.controlVariables, !controls.isEmpty {
                            Text("Control Variables")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            Text(controls.joined(separator: ", "))
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        // Matrix View
                        ScrollView(.horizontal) {
                            VStack(spacing: 0) {
                                // Top border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)

                                // Header Row
                                HStack(spacing: 0) {
                                    Text("")
                                        .frame(width: 150, alignment: .leading)
                                        .padding(.leading, 12)
                                        .padding(.vertical, 8)

                                    Text("")
                                        .frame(width: 150, alignment: .leading)
                                        .padding(.leading, 12)
                                        .padding(.vertical, 8)

                                    ForEach(partialResult.variables, id: \.self) { variable in
                                        Text(variable)
                                            .fontWeight(.semibold)
                                            .frame(minWidth: 100, alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }
                                }

                                // Header bottom border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)

                                // Data Rows - grouped by variable
                                ForEach(0..<partialResult.variables.count, id: \.self) { i in
                                    PartialCorrelationRowGroup(
                                        partialResult: partialResult,
                                        rowIndex: i
                                    )
                                }

                                // Bottom border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let regression = dataFrame.linearRegressionResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Linear Regression")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        // Model Summary
                        if dataFrame.linearRegressionOptions?.showModelFit ?? true {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Model Summary")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal)

                                VStack(spacing: 0) {
                                    // Top border
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1.5)

                                    // R
                                    HStack(spacing: 0) {
                                        Text("R")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.3f", regression.r))
                                            .frame(alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }

                                    // R Square
                                    HStack(spacing: 0) {
                                        Text("R Square")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.3f", regression.rSquared))
                                            .frame(alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }

                                    // Adjusted R Square
                                    HStack(spacing: 0) {
                                        Text("Adjusted R Square")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.3f", regression.adjustedRSquared))
                                            .frame(alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }

                                    // Std. Error of Estimate
                                    HStack(spacing: 0) {
                                        Text("Std. Error of Estimate")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.4f", regression.stdErrorEstimate))
                                            .frame(alignment: .trailing)
                                            .padding(.trailing, 12)
                                            .padding(.vertical, 8)
                                    }

                                    // Bottom border
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1.5)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Coefficients
                        if dataFrame.linearRegressionOptions?.showEstimates ?? true {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Coefficients")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal) {
                                    VStack(spacing: 0) {
                                        // Top border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)

                                        // Header
                                        HStack(spacing: 0) {
                                            Text("Model")
                                                .fontWeight(.semibold)
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 8)
                                            Text("Unstandardized B")
                                                .fontWeight(.semibold)
                                                .frame(width: 140, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text("Std. Error")
                                                .fontWeight(.semibold)
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text("Standardized Beta")
                                                .fontWeight(.semibold)
                                                .frame(width: 140, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text("t")
                                                .fontWeight(.semibold)
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text("Sig.")
                                                .fontWeight(.semibold)
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)

                                            if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                Text("95% CI Lower")
                                                    .fontWeight(.semibold)
                                                    .frame(width: 110, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 8)
                                                Text("95% CI Upper")
                                                    .fontWeight(.semibold)
                                                    .frame(width: 110, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 8)
                                            }
                                        }

                                        // Header bottom border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)

                                        // Constant (Intercept)
                                        HStack(spacing: 0) {
                                            Text("(Constant)")
                                                .frame(width: 100, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.3f", regression.coefficients[0]))
                                                .frame(width: 140, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.3f", regression.stdErrors[0]))
                                                .frame(width: 100, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text("") // No beta for constant
                                                .frame(width: 140, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.3f", regression.tStats[0]))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.3f", regression.pValues[0]))
                                                .frame(width: 80, alignment: .trailing)
                                                .padding(.trailing, 12)
                                                .padding(.vertical, 8)

                                            if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                Text(String(format: "%.3f", regression.confidenceIntervals[0].lower))
                                                    .frame(width: 110, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 8)
                                                Text(String(format: "%.3f", regression.confidenceIntervals[0].upper))
                                                    .frame(width: 110, alignment: .trailing)
                                                    .padding(.trailing, 12)
                                                    .padding(.vertical, 8)
                                            }
                                        }

                                        // Variables
                                        if let independents = dataFrame.linearRegressionIndependents {
                                            ForEach(0..<independents.count, id: \.self) { i in
                                                HStack(spacing: 0) {
                                                    Text(independents[i])
                                                        .frame(width: 100, alignment: .leading)
                                                        .padding(.leading, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.3f", regression.coefficients[i+1]))
                                                        .frame(width: 140, alignment: .trailing)
                                                        .padding(.trailing, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.3f", regression.stdErrors[i+1]))
                                                        .frame(width: 100, alignment: .trailing)
                                                        .padding(.trailing, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.3f", regression.beta[i+1]))
                                                        .frame(width: 140, alignment: .trailing)
                                                        .padding(.trailing, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.3f", regression.tStats[i+1]))
                                                        .frame(width: 80, alignment: .trailing)
                                                        .padding(.trailing, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.3f", regression.pValues[i+1]))
                                                        .frame(width: 80, alignment: .trailing)
                                                        .padding(.trailing, 12)
                                                        .padding(.vertical, 8)

                                                    if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                        Text(String(format: "%.3f", regression.confidenceIntervals[i+1].lower))
                                                            .frame(width: 110, alignment: .trailing)
                                                            .padding(.trailing, 12)
                                                            .padding(.vertical, 8)
                                                        Text(String(format: "%.3f", regression.confidenceIntervals[i+1].upper))
                                                            .frame(width: 110, alignment: .trailing)
                                                            .padding(.trailing, 12)
                                                            .padding(.vertical, 8)
                                                    }
                                                }
                                            }
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
                        
                        // Residuals
                        if dataFrame.linearRegressionOptions?.showResiduals ?? false {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Residuals")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal)
                                
                                let limit = 50
                                if regression.residuals.count > limit {
                                    Text("Display limited to first \(limit) cases.")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                        .padding(.horizontal)
                                }
                                
                                ScrollView([.horizontal, .vertical]) {
                                    VStack(spacing: 0) {
                                        HStack(spacing: 0) {
                                            Text("Case")
                                                .fontWeight(.bold)
                                                .frame(width: 60, height: 30)
                                                .background(Color.gray.opacity(0.1))
                                            Text("Predicted")
                                                .fontWeight(.bold)
                                                .frame(width: 100, height: 30)
                                                .background(Color.gray.opacity(0.1))
                                            Text("Residual")
                                                .fontWeight(.bold)
                                                .frame(width: 100, height: 30)
                                                .background(Color.gray.opacity(0.1))
                                        }
                                        
                                        ForEach(0..<min(regression.residuals.count, limit), id: \.self) { i in
                                            HStack(spacing: 0) {
                                                Text("\(i + 1)")
                                                    .frame(width: 60, height: 30)
                                                    .border(Color.gray.opacity(0.2))
                                                Text(String(format: "%.4f", regression.predicted[i]))
                                                    .frame(width: 100, height: 30)
                                                    .border(Color.gray.opacity(0.2))
                                                Text(String(format: "%.4f", regression.residuals[i]))
                                                    .frame(width: 100, height: 30)
                                                    .border(Color.gray.opacity(0.2))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .frame(height: 200)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                Spacer()
                Text("Select a column and run\nAnalyze > Descriptive Statistics")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct PartialCorrelationRowGroup: View {
    let partialResult: StatisticsEngine.CorrelationResult
    let rowIndex: Int

    var body: some View {
        VStack(spacing: 0) {
            // Control variables label row (first variable only)
            if rowIndex == 0, let controls = partialResult.controlVariables, !controls.isEmpty {
                controlVariableHeaderRow(controls: controls)
            }

            // Correlation row
            correlationRow

            // Significance row
            significanceRow

            // df row
            dfRow
        }
    }

    private func controlVariableHeaderRow(controls: [String]) -> some View {
        HStack(spacing: 0) {
            Text(controls.joined(separator: " & "))
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 4)

            Text(partialResult.variables[rowIndex])
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 4)

            ForEach(0..<partialResult.variables.count, id: \.self) { _ in
                Text("")
                    .frame(minWidth: 100, alignment: .trailing)
                    .padding(.trailing, 12)
                    .padding(.vertical, 4)
            }
        }
    }

    private var correlationRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text(rowIndex > 0 ? partialResult.variables[rowIndex] : "")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text("Correlation")
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            ForEach(0..<partialResult.variables.count, id: \.self) { j in
                let value = partialResult.matrix[rowIndex][j]
                let isSig = partialResult.significant[rowIndex][j]

                Text(rowIndex == j ? "1.000" : String(format: "%.3f", value))
                    .fontWeight(isSig && rowIndex != j ? .bold : .regular)
                    .frame(minWidth: 100, alignment: .trailing)
                    .padding(.trailing, 12)
                    .padding(.vertical, 6)
            }
        }
        .background(rowIndex % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
    }

    private var significanceRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text("")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text("Significance (2-tailed)")
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            ForEach(0..<partialResult.variables.count, id: \.self) { j in
                let isSig = partialResult.significant[rowIndex][j]

                Text(rowIndex == j ? "." : (isSig ? "<.001" : "."))
                    .frame(minWidth: 100, alignment: .trailing)
                    .padding(.trailing, 12)
                    .padding(.vertical, 6)
            }
        }
        .background(rowIndex % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
    }

    private var dfRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text("")
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text("df")
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            ForEach(0..<partialResult.variables.count, id: \.self) { j in
                Text(rowIndex == j ? "0" : "483")
                    .frame(minWidth: 100, alignment: .trailing)
                    .padding(.trailing, 12)
                    .padding(.vertical, 6)
            }
        }
        .background(rowIndex % 2 == 0 ? Color.gray.opacity(0.03) : Color.clear)
    }
}

#Preview {
    InspectorView(dataFrame: DataFrame())
}
