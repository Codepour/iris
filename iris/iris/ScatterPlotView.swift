import SwiftUI
import Charts

struct ScatterPlotView: View {
    let data: [(x: Double, y: Double)]
    let title: String
    let xAxisLabel: String
    let yAxisLabel: String
    let color: Color
    
    init(data: [(x: Double, y: Double)], title: String = "", xAxisLabel: String = "X", yAxisLabel: String = "Y", color: Color = .blue) {
        self.data = data
        self.title = title
        self.xAxisLabel = xAxisLabel
        self.yAxisLabel = yAxisLabel
        self.color = color
    }
    
    struct PointData: Identifiable {
        let id = UUID()
        let x: Double
        let y: Double
    }
    
    var chartData: [PointData] {
        data.map { PointData(x: $0.x, y: $0.y) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if !title.isEmpty {
                Text(title)
                    .font(.headline)
                    .padding(.top)
            }
            
            Chart(chartData) { point in
                PointMark(
                    x: .value(xAxisLabel, point.x),
                    y: .value(yAxisLabel, point.y)
                )
                .foregroundStyle(color)
            }
            .chartXAxis {
                AxisMarks(position: .bottom, values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.black)
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.gray.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.black)
                    AxisValueLabel()
                }
            }
            .chartXAxisLabel(position: .bottom, alignment: .center) {
                Text(xAxisLabel)
                    .font(.subheadline)
                    .bold()
            }
            .chartYAxisLabel(position: .leading, alignment: .center) {
                Text(yAxisLabel)
                    .font(.subheadline)
                    .bold()
            }
            .padding()
        }
    }
}
