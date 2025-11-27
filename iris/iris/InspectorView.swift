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
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        APATableView(data: DescriptiveStatsTable(stats: stats))
                    }
                    .padding(.vertical)
                }
            } else if let correlation = dataFrame.correlationResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Correlations")
                            .font(.system(.headline, design: .serif).bold())
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
                                            .font(.system(.body, design: .serif).bold())
                                            .frame(minWidth: 100, alignment: .center)
                                            .padding(.horizontal, 16)
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
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            Text("\(correlation.method == .pearson ? "Pearson" : "Spearman") Correlation")
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            ForEach(0..<correlation.variables.count, id: \.self) { j in
                                                let value = correlation.matrix[i][j]
                                                let isSig = correlation.significant[i][j]

                                                Text(i == j ? "1.000" : formatCorrelation(value))
                                                    .font(.system(.body, design: .serif))
                                                    .fontWeight(isSig && i != j ? .bold : .regular)
                                                    .frame(minWidth: 100, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                            }
                                        }

                                        // Significance row
                                        HStack(spacing: 0) {
                                            Text("")
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            Text("Sig. (\(correlation.testType == .twoTailed ? "2" : "1")-tailed)")
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 150, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 6)

                                            ForEach(0..<correlation.variables.count, id: \.self) { j in
                                                let isSig = correlation.significant[i][j]

                                                Text(i == j ? "" : (isSig ? "< .001" : ""))
                                                    .font(.system(.body, design: .serif))
                                                    .frame(minWidth: 100, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                            }
                                        }
                                    }
                                }

                                // Bottom border
                                Rectangle()
                                    .fill(Color.primary)
                                    .frame(height: 1.5)
                            }
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal)
                        }

                        // Note
                        if correlation.significant.flatMap({ $0 }).contains(true) {
                            let tailedText = correlation.testType == .twoTailed ? "2-tailed" : "1-tailed"
                            Text("Note. Correlation is significant at the .001 level (\(tailedText)).")
                                .font(.system(.caption, design: .serif).italic())
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let distributions = dataFrame.distributionResults {
                DistributionAnalysisView(distributions: distributions)
            } else if let partialResult = dataFrame.partialCorrelationResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Partial Correlations")
                            .font(.system(.headline, design: .serif).bold())
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
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let regression = dataFrame.linearRegressionResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Linear Regression")
                            .font(.system(.headline, design: .serif).bold())
                            .padding(.horizontal)
                        
                        // Model Summary
                        if dataFrame.linearRegressionOptions?.showModelFit ?? true {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Model Summary")
                                    .font(.system(.subheadline, design: .serif).bold())
                                    .padding(.horizontal)

                                VStack(spacing: 0) {
                                    // Top border
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1.5)

                                    // R
                                    HStack(spacing: 0) {
                                        Text("R")
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 150, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.2f", regression.r))
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 100, alignment: .center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }

                                    // R Square
                                    HStack(spacing: 0) {
                                        Text("R²")
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 150, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.2f", regression.rSquared))
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 100, alignment: .center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }

                                    // Adjusted R Square
                                    HStack(spacing: 0) {
                                        Text("Adjusted R²")
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 150, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.2f", regression.adjustedRSquared))
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 100, alignment: .center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }

                                    // Std. Error of Estimate
                                    HStack(spacing: 0) {
                                        Text("SE")
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 150, alignment: .leading)
                                            .padding(.leading, 12)
                                            .padding(.vertical, 8)
                                        Text(String(format: "%.2f", regression.stdErrorEstimate))
                                            .font(.system(.body, design: .serif))
                                            .frame(width: 100, alignment: .center)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                    }

                                    // Bottom border
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(height: 1.5)
                                }
                                .fixedSize(horizontal: true, vertical: false)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Coefficients
                        if dataFrame.linearRegressionOptions?.showEstimates ?? true {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Coefficients")
                                    .font(.system(.subheadline, design: .serif).bold())
                                    .padding(.horizontal)

                                ScrollView(.horizontal) {
                                    VStack(spacing: 0) {
                                        // Top border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)

                                        // Header
                                        HStack(spacing: 0) {
                                            Text("Variable")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 120, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 8)
                                            Text("B")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("SE")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("β")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("t")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 80, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("p")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 80, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)

                                            if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                Text("95% CI")
                                                    .font(.system(.body, design: .serif).bold())
                                                    .frame(width: 200, alignment: .center)
                                                    .padding(.horizontal, 16)
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
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 120, alignment: .leading)
                                                .padding(.leading, 12)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.2f", regression.coefficients[0]))
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.2f", regression.stdErrors[0]))
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("")
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 100, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text(String(format: "%.2f", regression.tStats[0]))
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 80, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text(formatPValue(regression.pValues[0]))
                                                .font(.system(.body, design: .serif))
                                                .frame(width: 80, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)

                                            if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                Text("[\(String(format: "%.2f", regression.confidenceIntervals[0].lower)), \(String(format: "%.2f", regression.confidenceIntervals[0].upper))]")
                                                    .font(.system(.body, design: .serif))
                                                    .frame(width: 200, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                            }
                                        }

                                        // Variables
                                        if let independents = dataFrame.linearRegressionIndependents {
                                            ForEach(0..<independents.count, id: \.self) { i in
                                                HStack(spacing: 0) {
                                                    Text(independents[i])
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 120, alignment: .leading)
                                                        .padding(.leading, 12)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.2f", regression.coefficients[i+1]))
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 100, alignment: .center)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.2f", regression.stdErrors[i+1]))
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 100, alignment: .center)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                    Text(formatCorrelation(regression.beta[i+1]))
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 100, alignment: .center)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                    Text(String(format: "%.2f", regression.tStats[i+1]))
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 80, alignment: .center)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                    Text(formatPValue(regression.pValues[i+1]))
                                                        .font(.system(.body, design: .serif))
                                                        .frame(width: 80, alignment: .center)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)

                                                    if dataFrame.linearRegressionOptions?.showConfidenceIntervals ?? false {
                                                        Text("[\(String(format: "%.2f", regression.confidenceIntervals[i+1].lower)), \(String(format: "%.2f", regression.confidenceIntervals[i+1].upper))]")
                                                            .font(.system(.body, design: .serif))
                                                            .frame(width: 200, alignment: .center)
                                                            .padding(.horizontal, 16)
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
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Residuals
                        if dataFrame.linearRegressionOptions?.showResiduals ?? false {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Residuals")
                                    .font(.system(.subheadline, design: .serif).bold())
                                    .padding(.horizontal)

                                let limit = 50
                                if regression.residuals.count > limit {
                                    Text("Note. Display limited to first \(limit) cases.")
                                        .font(.system(.caption, design: .serif).italic())
                                        .padding(.horizontal)
                                }

                                ScrollView([.horizontal, .vertical]) {
                                    VStack(spacing: 0) {
                                        // Top border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)

                                        // Header
                                        HStack(spacing: 0) {
                                            Text("Case")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 80, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("Predicted")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 120, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                            Text("Residual")
                                                .font(.system(.body, design: .serif).bold())
                                                .frame(width: 120, alignment: .center)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                        }

                                        // Header bottom border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)

                                        ForEach(0..<min(regression.residuals.count, limit), id: \.self) { i in
                                            HStack(spacing: 0) {
                                                Text("\(i + 1)")
                                                    .font(.system(.body, design: .serif))
                                                    .frame(width: 80, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                                Text(String(format: "%.2f", regression.predicted[i]))
                                                    .font(.system(.body, design: .serif))
                                                    .frame(width: 120, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                                Text(String(format: "%.2f", regression.residuals[i]))
                                                    .font(.system(.body, design: .serif))
                                                    .frame(width: 120, alignment: .center)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 6)
                                            }
                                        }

                                        // Bottom border
                                        Rectangle()
                                            .fill(Color.primary)
                                            .frame(height: 1.5)
                                    }
                                    .fixedSize(horizontal: true, vertical: false)
                                    .padding(.horizontal)
                                }
                                .frame(height: 200)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            } else {
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

// Helper function for APA correlation formatting (no leading zero)
func formatCorrelation(_ value: Double) -> String {
    let formatted = String(format: "%.3f", value)
    // Remove leading zero if present
    if formatted.hasPrefix("0.") {
        return String(formatted.dropFirst())
    } else if formatted.hasPrefix("-0.") {
        return "-" + String(formatted.dropFirst(2))
    }
    return formatted
}

// Helper function for APA p-value formatting (no leading zero)
func formatPValue(_ value: Double) -> String {
    if value < 0.001 {
        return "< .001"
    }
    let formatted = String(format: "%.3f", value)
    // Remove leading zero if present
    if formatted.hasPrefix("0.") {
        return String(formatted.dropFirst())
    }
    return formatted
}

struct DescriptiveStatsTable: APAReportable {
    let stats: DescriptiveStatistics

    var tableNumber: Int? { nil }
    var title: String { "Descriptive Statistics" }

    var columns: [APAColumn] {
        [
            APAColumn(header: "Statistic", alignment: .left, width: 150),
            APAColumn(header: "Value", alignment: .center, width: 100)
        ]
    }

    var rows: [APARow] {
        var result: [APARow] = []

        // Basic Measures
        result.append(APARow(items: ["Count", "\(stats.count)"]))
        result.append(APARow(items: ["Mean", String(format: "%.2f", stats.mean)]))
        result.append(APARow(items: ["Median", String(format: "%.2f", stats.median)]))
        if let mode = stats.mode {
            result.append(APARow(items: ["Mode", String(format: "%.2f", mode)]))
        }

        // Spread
        result.append(APARow(items: ["Variance", String(format: "%.2f", stats.variance)]))
        result.append(APARow(items: ["SD", String(format: "%.2f", stats.standardDeviation)]))
        result.append(APARow(items: ["Range", String(format: "%.2f", stats.range)]))
        result.append(APARow(items: ["Min", String(format: "%.2f", stats.min)]))
        result.append(APARow(items: ["Max", String(format: "%.2f", stats.max)]))

        // Shape
        result.append(APARow(items: ["Skewness", String(format: "%.2f", stats.skewness)]))
        result.append(APARow(items: ["Kurtosis", String(format: "%.2f", stats.kurtosis)]))

        // Quartiles
        result.append(APARow(items: ["Q1", String(format: "%.2f", stats.q1)]))
        result.append(APARow(items: ["Q2", String(format: "%.2f", stats.q2)]))
        result.append(APARow(items: ["Q3", String(format: "%.2f", stats.q3)]))
        result.append(APARow(items: ["IQR", String(format: "%.2f", stats.iqr)]))

        return result
    }

    var note: String? { nil }
}

#Preview {
    InspectorView(dataFrame: DataFrame())
}
