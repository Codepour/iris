import Foundation
import SwiftUI
import Combine

// MARK: - Output Item Protocol & Types

/// Represents a single output item that can be added to the output collection
enum OutputItemType: String, Codable {
    case descriptiveStatistics
    case correlation
    case partialCorrelation
    case distribution
    case distances
    case linearRegression
    case scatterPlot
}

/// A wrapper for any output result that can be stored in the output collection
struct OutputItem: Identifiable {
    let id = UUID()
    let type: OutputItemType
    let timestamp: Date
    let title: String
    let data: Any
    
    // For correlation results
    struct CorrelationData {
        let result: StatisticsEngine.CorrelationResult
    }
    
    // For distribution results
    struct DistributionData {
        let results: [DataFrame.DistributionResult]
    }
    
    // For linear regression
    struct LinearRegressionData {
        let result: StatisticsEngine.LinearRegressionResult
        let dependent: String
        let independents: [String]
        let options: DataFrame.LinearRegressionOptions
    }
    
    // For scatter plot
    struct ScatterPlotData {
        let data: [(x: Double, y: Double)]
        let title: String
        let xLabel: String
        let yLabel: String
    }
    
    // For distance matrix
    struct DistanceData {
        let matrix: [[Double]]
        let metric: StatisticsEngine.DistanceMetric
    }
    
    // For descriptive statistics
    struct DescriptiveData {
        let stats: DescriptiveStatistics
    }
}

// MARK: - Output Collection Manager

class OutputCollection: ObservableObject {
    @Published var items: [OutputItem] = []
    
    func addItem(_ item: OutputItem) {
        items.insert(item, at: 0) // Add new items at the top
    }
    
    func removeItem(_ item: OutputItem) {
        items.removeAll { $0.id == item.id }
    }
    
    func clearAll() {
        items.removeAll()
    }
}

// MARK: - Industry Standard Sizing Constants
// Based on SPSS/STATA/SAS output standards

struct OutputSizing {
    // MARK: - APA 7th Edition Table Standards
    // Tables should size to content, not stretch to fill
    
    // Column widths (consistent across all tables)
    static let stubColumnWidth: CGFloat = 140      // First column (row labels)
    static let labelColumnWidth: CGFloat = 140     // Secondary label columns  
    static let dataColumnWidth: CGFloat = 80       // Numeric data columns
    static let wideDataColumnWidth: CGFloat = 100  // Wider numeric columns (correlations, etc.)
    static let ciColumnWidth: CGFloat = 140        // Confidence intervals [x.xx, x.xx]
    static let caseColumnWidth: CGFloat = 60       // Case numbers
    
    // Cell padding (APA uses moderate spacing)
    static let cellHorizontalPadding: CGFloat = 8
    static let cellVerticalPadding: CGFloat = 6    // Header rows
    static let dataCellVerticalPadding: CGFloat = 5 // Data rows (slightly tighter)
    
    // Border thickness
    static let borderThickness: CGFloat = 1.5
    
    // MARK: - Popup Sizes
    static let configPopupWidth: CGFloat = 480
    static let configPopupMinHeight: CGFloat = 400
    static let configPopupMaxHeight: CGFloat = 600
    
    static let resultPopupWidth: CGFloat = 700
    static let resultPopupMinHeight: CGFloat = 400
    static let resultPopupMaxHeight: CGFloat = 700
    
    // MARK: - Legacy (kept for compatibility, prefer specific constants above)
    static let standardTableWidth: CGFloat = 600
    static let compactTableWidth: CGFloat = 450
    static let wideTableWidth: CGFloat = 800
    static let valueColumnWidth: CGFloat = 80
    static let statisticColumnWidth: CGFloat = 80
    static let headerFontSize: CGFloat = 12
    static let bodyFontSize: CGFloat = 11
    static let noteFontSize: CGFloat = 10
}
