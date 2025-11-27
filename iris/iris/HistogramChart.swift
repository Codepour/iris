import SwiftUI
import Charts

struct HistogramChart: View {
    let binEdges: [Double]
    let counts: [Int]
    let color: Color
    let xAxisLabel: String
    let yAxisLabel: String
    
    init(binEdges: [Double], counts: [Int], color: Color = .blue, xAxisLabel: String = "Value", yAxisLabel: String = "Frequency") {
        self.binEdges = binEdges
        self.counts = counts
        self.color = color
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
    }
    
    struct BinData: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
    }
    
    var data: [BinData] {
        var bins: [BinData] = []
        guard binEdges.count > 1, counts.count == binEdges.count - 1 else { return [] }
        
        for i in 0..<counts.count {
            let start = binEdges[i]
            let end = binEdges[i+1]
            let label = "\(String(format: "%.1f", start)) - \(String(format: "%.1f", end))"
            bins.append(BinData(label: label, count: counts[i]))
        }
        return bins
    }
    
    var body: some View {
        Chart(data) { bin in
            BarMark(
                x: .value("Range", bin.label),
                y: .value("Count", bin.count)
            )
            .foregroundStyle(color)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXAxisLabel(xAxisLabel)
        .chartYAxisLabel(yAxisLabel)
    }
}
