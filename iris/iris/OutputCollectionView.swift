import SwiftUI

/// View that displays the collection of output items
struct OutputCollectionView: View {
    @ObservedObject var dataFrame: DataFrame
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                
                if !dataFrame.outputCollection.items.isEmpty {
                    Button(action: {
                        dataFrame.outputCollection.clearAll()
                    }) {
                        Label("Clear All", systemImage: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding()
            
            Divider()
            
            if dataFrame.outputCollection.items.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No output yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Run an analysis from the Analyze menu\nand click 'Add to Output' to see results here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        ForEach(dataFrame.outputCollection.items) { item in
                            OutputItemView(item: item, dataFrame: dataFrame)
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

/// View for a single output item
struct OutputItemView: View {
    let item: OutputItem
    @ObservedObject var dataFrame: DataFrame
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: { isExpanded.toggle() }) {
                    HStack {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.secondary)
                        Text(item.title)
                            .font(.system(.subheadline, design: .serif).bold())
                        Text(formattedTimestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {
                    dataFrame.outputCollection.removeItem(item)
                }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 8)
            
            // Content
            if isExpanded {
                ScrollView(.horizontal, showsIndicators: true) {
                    outputContent
                        .fixedSize(horizontal: true, vertical: false)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.timestamp)
    }
    
    @ViewBuilder
    private var outputContent: some View {
        switch item.type {
        case .descriptiveStatistics:
            if let data = item.data as? OutputItem.DescriptiveData {
                APATableView(data: DescriptiveStatsTable(stats: data.stats))
            }
            
        case .correlation:
            if let data = item.data as? OutputItem.CorrelationData {
                CorrelationResultView(correlation: data.result)
            }
            
        case .partialCorrelation:
            if let data = item.data as? OutputItem.CorrelationData {
                PartialCorrelationResultView(partialResult: data.result)
            }
            
        case .distribution:
            if let data = item.data as? OutputItem.DistributionData {
                DistributionAnalysisView(distributions: data.results)
            }
            
        case .distances:
            if let data = item.data as? OutputItem.DistanceData {
                DistanceResultView(matrix: data.matrix, metric: data.metric)
            }
            
        case .linearRegression:
            if let data = item.data as? OutputItem.LinearRegressionData {
                LinearRegressionResultView(
                    regression: data.result,
                    dependent: data.dependent,
                    independents: data.independents,
                    options: data.options
                )
            }
            
        case .scatterPlot:
            if let data = item.data as? OutputItem.ScatterPlotData {
                ScatterPlotView(
                    data: data.data,
                    title: data.title,
                    xAxisLabel: data.xLabel,
                    yAxisLabel: data.yLabel
                )
                .frame(height: 400)
            }
        }
    }
}

#Preview {
    OutputCollectionView(dataFrame: DataFrame())
}
