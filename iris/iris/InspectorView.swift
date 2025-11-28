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
                CorrelationResultView(correlation: correlation)
                    .padding()
            } else if let distributions = dataFrame.distributionResults {
                DistributionAnalysisView(distributions: distributions)
            } else if let partialResult = dataFrame.partialCorrelationResult {
                PartialCorrelationResultView(partialResult: partialResult)
                    .padding()
            } else if let regression = dataFrame.linearRegressionResult {
                LinearRegressionResultView(
                    regression: regression,
                    dependent: dataFrame.linearRegressionDependent ?? "Dependent",
                    independents: dataFrame.linearRegressionIndependents ?? [],
                    options: dataFrame.linearRegressionOptions
                )
                .padding()
            } else if let scatterData = dataFrame.scatterPlotData {
                ScatterPlotView(
                    data: scatterData,
                    title: dataFrame.scatterPlotTitle,
                    xAxisLabel: dataFrame.scatterPlotXLabel,
                    yAxisLabel: dataFrame.scatterPlotYLabel
                )
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

// Note: PartialCorrelationRowGroup is now in ResultViews.swift

// Note: formatCorrelation and formatPValue are now in APATableComponents.swift

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
