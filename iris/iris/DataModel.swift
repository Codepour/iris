import Foundation
import Combine
import SwiftUI

struct Cell: Identifiable, Hashable {
    let id = UUID()
    var value: String
    var row: Int
    var col: Int
}

enum Selection: Equatable {
    case none
    case row(Int)
    case column(Int)
    case cell(Int, Int)
    case range(Int, Int, Int, Int) // startRow, startCol, endRow, endCol
}

enum MeasureType: String, CaseIterable {
    case nominal
    case ordinal
    case interval
    case ratio
    
    var iconName: String {
        switch self {
        case .nominal: return "circle.grid.2x2.fill"
        case .ordinal: return "chart.bar.fill"
        case .interval: return "ruler.fill"
        case .ratio: return "percent"
        }
    }
    
    var color: Color {
        switch self {
        case .nominal: return .orange
        case .ordinal: return .blue
        case .interval: return .yellow
        case .ratio: return .green
        }
    }
}

class DataFrame: ObservableObject {
    @Published var headers: [String]
    @Published var data: [Cell]
    @Published var rowCount: Int
    @Published var colCount: Int
    @Published var selection: Selection = .none
    @Published var columnTypes: [MeasureType]
    
    private var selectionStart: (row: Int, col: Int)?
    
    func startSelection(row: Int, col: Int) {
        selectionStart = (row, col)
        selection = .cell(row, col)
    }
    
    func updateSelection(row: Int, col: Int) {
        guard let start = selectionStart else { return }
        let minRow = min(start.row, row)
        let maxRow = max(start.row, row)
        let minCol = min(start.col, col)
        let maxCol = max(start.col, col)
        
        if minRow == maxRow && minCol == maxCol {
            selection = .cell(minRow, minCol)
        } else {
            selection = .range(minRow, minCol, maxRow, maxCol)
        }
    }
    
    func updateColumnType(col: Int, type: MeasureType) {
        if col < columnTypes.count {
            columnTypes[col] = type
        }
    }
    
    init(rows: Int = 50, cols: Int = 10) {
        self.rowCount = rows
        self.colCount = cols
        self.headers = (0..<cols).map { String(UnicodeScalar(65 + $0)!) } // A, B, C...
        self.data = []
        self.columnTypes = Array(repeating: .nominal, count: cols)
        
        // Populate with dummy data
        for r in 0..<rows {
            for c in 0..<cols {
                self.data.append(Cell(value: "", row: r, col: c))
            }
        }
    }
    
    func updateCell(row: Int, col: Int, value: String) {
        if let index = data.firstIndex(where: { $0.row == row && $0.col == col }) {
            data[index].value = value
        }
    }
    
    func getCell(row: Int, col: Int) -> String {
        return data.first(where: { $0.row == row && $0.col == col })?.value ?? ""
    }
    
    func loadCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let rows = parseCSV(content)
            
            guard !rows.isEmpty else { return }
            
            // Assume first row is headers
            let newHeaders = rows[0]
            let newColCount = newHeaders.count
            let newRowCount = rows.count - 1
            
            DispatchQueue.main.async {
                self.headers = newHeaders
                self.colCount = newColCount
                self.rowCount = newRowCount
                self.data = []
                self.columnTypes = Array(repeating: .nominal, count: newColCount)
                
                for (rIndex, row) in rows.dropFirst().enumerated() {
                    for (cIndex, value) in row.enumerated() {
                        if cIndex < newColCount {
                            self.data.append(Cell(value: value, row: rIndex, col: cIndex))
                        }
                    }
                }
                
                self.detectColumnTypes()
            }
        } catch {
            print("Error loading CSV: \(error)")
        }
    }
    
    private func detectColumnTypes() {
        for col in 0..<colCount {
            let columnValues = data.filter { $0.col == col }.map { $0.value }
            let nonEmptyValues = columnValues.filter { !$0.isEmpty }
            
            if nonEmptyValues.isEmpty {
                columnTypes[col] = .nominal
                continue
            }
            
            let isNumeric = nonEmptyValues.allSatisfy { Double($0) != nil }
            
            if isNumeric {
                columnTypes[col] = .ratio
            } else {
                columnTypes[col] = .nominal
            }
        }
    }
    
    private func parseCSV(_ content: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in content {
            if insideQuotes {
                if char == "\"" {
                    insideQuotes = false
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    insideQuotes = true
                } else if char == "," {
                    currentRow.append(currentField)
                    currentField = ""
                } else if char == "\n" || char == "\r\n" {
                    currentRow.append(currentField)
                    result.append(currentRow)
                    currentRow = []
                    currentField = ""
                } else {
                    currentField.append(char)
                }
            }
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            result.append(currentRow)
        }
        
        return result
    }
    
    func isSelected(row: Int, col: Int) -> Bool {
        switch selection {
        case .none:
            return false
        case .row(let r):
            return r == row
        case .column(let c):
            return c == col
        case .cell(let r, let c):
            return r == row && c == col
        case .range(let r1, let c1, let r2, let c2):
            return row >= r1 && row <= r2 && col >= c1 && col <= c2
        }
    }
    
    // MARK: - Formula Bar Helpers
    
    var selectedCellInfo: String {
        let r: Int
        let c: Int
        
        switch selection {
        case .cell(let row, let col):
            r = row
            c = col
        case .range(let row, let col, _, _):
            r = row
            c = col
        default:
            return ""
        }
        
        let header = headers.indices.contains(c) ? headers[c] : ""
        return "\(header): \(r + 1)"
    }
    
    var selectedCellValue: String {
        get {
            if case .cell(let r, let c) = selection {
                return getCell(row: r, col: c)
            } else if case .range(let r, let c, _, _) = selection {
                return getCell(row: r, col: c)
            }
            return ""
        }
        set {
            if case .cell(let r, let c) = selection {
                updateCell(row: r, col: c, value: newValue)
            } else if case .range(let r, let c, _, _) = selection {
                updateCell(row: r, col: c, value: newValue)
            }
        }
    }
    
    func getAddress(row: Int, col: Int) -> String {
        let colStr = String(UnicodeScalar(65 + col)!) // Simple A-Z for now
        return "\(colStr)\(row + 1)"
    }
    
    func getCoordinates(from address: String) -> (row: Int, col: Int)? {
        let pattern = "^([A-Z]+)([0-9]+)$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsString = address as NSString
        let results = regex.matches(in: address, range: NSRange(location: 0, length: nsString.length))
        
        if let match = results.first {
            let colStr = nsString.substring(with: match.range(at: 1))
            let rowStr = nsString.substring(with: match.range(at: 2))
            
            if let colChar = colStr.first, let row = Int(rowStr) {
                let col = Int(colChar.asciiValue! - 65)
                return (row - 1, col)
            }
        }
        return nil
    }
    
    // MARK: - Statistics
    
    @Published var currentStatistics: DescriptiveStatistics?
    @Published var correlationResult: StatisticsEngine.CorrelationResult?
    private let statisticsEngine = StatisticsEngine()
    
    func calculateStatisticsForSelection() {
        // ... (existing code) ...
        var targetCol: Int?
        
        switch selection {
        case .column(let c):
            targetCol = c
        case .cell(_, let c):
            targetCol = c
        case .range(_, let c, _, _):
            // For now, just take the start column of the range
            targetCol = c
        default:
            break
        }
        
        guard let col = targetCol else { return }
        
        let numericValues = getNumericValues(for: col)
        if !numericValues.isEmpty {
            currentStatistics = statisticsEngine.calculateDescriptiveStatistics(for: numericValues)
            // Clear correlation result when running descriptive stats
            correlationResult = nil
        } else {
            currentStatistics = nil
        }
    }
    
    enum MissingValueStrategy {
        case listwise
        case pairwise
    }
    
    func runCorrelation(variables: [String], method: StatisticsEngine.CorrelationMethod, missingStrategy: MissingValueStrategy, testType: StatisticsEngine.SignificanceTestType) {
        
        if missingStrategy == .listwise {
            // Listwise Deletion: Exclude rows where ANY selected variable is missing
            let colIndices = variables.compactMap { headers.firstIndex(of: $0) }
            var cleanData: [[Double]] = Array(repeating: [], count: colIndices.count)
            
            for r in 0..<rowCount {
                var rowValues: [Double] = []
                var isComplete = true
                
                for col in colIndices {
                    let valStr = getCell(row: r, col: col)
                    if let val = Double(valStr) {
                        rowValues.append(val)
                    } else {
                        isComplete = false
                        break
                    }
                }
                
                if isComplete {
                    for i in 0..<colIndices.count {
                        cleanData[i].append(rowValues[i])
                    }
                }
            }
            
            if !cleanData.isEmpty && !cleanData[0].isEmpty {
                correlationResult = statisticsEngine.calculateCorrelationMatrix(data: cleanData, variables: variables, method: method, testType: testType)
                currentStatistics = nil
            }
            
        } else {
            // Pairwise Deletion: Calculate correlation for each pair using available data for that pair
            let numVars = variables.count
            var matrix = Array(repeating: Array(repeating: 0.0, count: numVars), count: numVars)
            var significant = Array(repeating: Array(repeating: false, count: numVars), count: numVars)
            
            let colIndices = variables.compactMap { headers.firstIndex(of: $0) }
            
            // Pre-fetch all columns as optional doubles to avoid repeated parsing
            var allCols: [[Double?]] = []
            for col in colIndices {
                var colValues: [Double?] = []
                for r in 0..<rowCount {
                    if let val = Double(getCell(row: r, col: col)) {
                        colValues.append(val)
                    } else {
                        colValues.append(nil)
                    }
                }
                allCols.append(colValues)
            }
            
            for i in 0..<numVars {
                for j in i..<numVars {
                    if i == j {
                        matrix[i][j] = 1.0
                        significant[i][j] = true
                    } else {
                        // Extract valid pairs
                        var x: [Double] = []
                        var y: [Double] = []
                        
                        for r in 0..<rowCount {
                            if let v1 = allCols[i][r], let v2 = allCols[j][r] {
                                x.append(v1)
                                y.append(v2)
                            }
                        }
                        
                        if x.count > 1 {
                            // Handle Rank for Spearman per pair
                            let xInput = method == .spearman ? statisticsEngine.rankData(x) : x
                            let yInput = method == .spearman ? statisticsEngine.rankData(y) : y
                            
                            let r = statisticsEngine.calculatePearsonCorrelation(x: xInput, y: yInput)
                            matrix[i][j] = r
                            matrix[j][i] = r
                            
                            let isSig = statisticsEngine.isSignificant(r: r, n: x.count, testType: testType)
                            significant[i][j] = isSig
                            significant[j][i] = isSig
                        }
                    }
                }
            }
            
            correlationResult = StatisticsEngine.CorrelationResult(matrix: matrix, variables: variables, significant: significant, method: method, controlVariables: nil, testType: testType)
            currentStatistics = nil
        }
    }
    
    func getNumericValues(for col: Int) -> [Double] {
        return data.filter { $0.col == col }
                   .compactMap { Double($0.value) }
    }

    
    struct DistributionResult {
        let variable: String
        let percentiles: [Double: Double]
        let zScoreOutliers: [(row: Int, value: Double, z: Double)]
        let frequencies: (counts: [Int], binEdges: [Double])?
    }
    
    @Published var distributionResults: [DistributionResult]?
    
    func runDistributionAnalysis(variables: [String], percentiles: [Double], showOutliers: Bool, showFrequencies: Bool, bins: Int) {
        var results: [DistributionResult] = []
        
        for variable in variables {
            guard let colIndex = headers.firstIndex(of: variable) else { continue }
            
            // Extract data with row indices for outlier tracking
            var values: [Double] = []
            var rowIndices: [Int] = []
            
            for r in 0..<rowCount {
                if let val = Double(getCell(row: r, col: colIndex)) {
                    values.append(val)
                    rowIndices.append(r)
                }
            }
            
            guard !values.isEmpty else { continue }
            
            // 1. Percentiles
            let percentileResults = statisticsEngine.calculatePercentiles(data: values, percentiles: percentiles)
            
            // 2. Z-Scores (Outliers)
            var outliers: [(row: Int, value: Double, z: Double)] = []
            if showOutliers {
                let zScores = statisticsEngine.calculateZScores(data: values)
                for (i, z) in zScores.enumerated() {
                    if abs(z) > 3.0 {
                        outliers.append((row: rowIndices[i], value: values[i], z: z))
                    }
                }
            }
            
            // 3. Frequencies
            var frequencyResult: (counts: [Int], binEdges: [Double])? = nil
            if showFrequencies {
                frequencyResult = statisticsEngine.calculateFrequencies(data: values, bins: bins)
            }
            
            results.append(DistributionResult(
                variable: variable,
                percentiles: percentileResults,
                zScoreOutliers: outliers,
                frequencies: frequencyResult
            ))
        }
        
        distributionResults = results
        currentStatistics = nil
        correlationResult = nil
    }
    
    // MARK: - Partial Correlation
    
    @Published var partialCorrelationResult: StatisticsEngine.CorrelationResult?
    
    func runPartialCorrelation(variables: [String], controls: [String], testType: StatisticsEngine.SignificanceTestType) {
        // Extract data for all variables (vars + controls)
        let allVars = variables + controls
        var dataMatrix: [[Double]] = []
        
        // Use listwise deletion for now (simplest for matrix inversion)
        // Find rows where all vars + controls are present
        var validRows: [Int] = []
        
        for r in 0..<rowCount {
            var isValid = true
            for v in allVars {
                guard let colIndex = headers.firstIndex(of: v),
                      let _ = Double(getCell(row: r, col: colIndex)) else {
                    isValid = false
                    break
                }
            }
            if isValid {
                validRows.append(r)
            }
        }
        
        guard !validRows.isEmpty else { return }
        
        // Build matrix [Variable][Row]
        for v in allVars {
            guard let colIndex = headers.firstIndex(of: v) else { continue }
            var colData: [Double] = []
            for r in validRows {
                if let val = Double(getCell(row: r, col: colIndex)) {
                    colData.append(val)
                }
            }
            dataMatrix.append(colData)
        }
        
        partialCorrelationResult = statisticsEngine.calculatePartialCorrelations(data: dataMatrix, variables: variables, controls: controls)
        
        // Clear others
        currentStatistics = nil
        correlationResult = nil
        distributionResults = nil
        distanceResult = nil
    }
    
    // MARK: - Distances
    
    @Published var distanceResult: [[Double]]?
    @Published var distanceMetric: StatisticsEngine.DistanceMetric?
    
    func runDistances(variables: [String], metric: StatisticsEngine.DistanceMetric) {
        var dataMatrix: [[Double]] = []
        
        // Use listwise deletion
        var validRows: [Int] = []
        for r in 0..<rowCount {
            var isValid = true
            for v in variables {
                guard let colIndex = headers.firstIndex(of: v),
                      let _ = Double(getCell(row: r, col: colIndex)) else {
                    isValid = false
                    break
                }
            }
            if isValid {
                validRows.append(r)
            }
        }
        
        guard !validRows.isEmpty else { return }
        
        for v in variables {
            guard let colIndex = headers.firstIndex(of: v) else { continue }
            var colData: [Double] = []
            for r in validRows {
                if let val = Double(getCell(row: r, col: colIndex)) {
                    colData.append(val)
                }
            }
            dataMatrix.append(colData)
        }
        
        distanceResult = statisticsEngine.calculateDistances(data: dataMatrix, metric: metric)
        distanceMetric = metric
        
        // Clear others
        currentStatistics = nil
        correlationResult = nil
        distributionResults = nil
        partialCorrelationResult = nil
        linearRegressionResult = nil
    }
    
    // MARK: - Linear Regression
    
    struct LinearRegressionOptions {
        var showEstimates: Bool
        var showModelFit: Bool
        var showConfidenceIntervals: Bool
        var showResiduals: Bool
    }
    
    @Published var linearRegressionResult: StatisticsEngine.LinearRegressionResult?
    @Published var linearRegressionDependent: String?
    @Published var linearRegressionIndependents: [String]?
    @Published var linearRegressionOptions: LinearRegressionOptions?
    
    func runLinearRegression(dependent: String, independents: [String], options: LinearRegressionOptions) {
        // Listwise deletion
        var validRows: [Int] = []
        let allVars = [dependent] + independents
        
        for r in 0..<rowCount {
            var isValid = true
            for v in allVars {
                guard let colIndex = headers.firstIndex(of: v),
                      let _ = Double(getCell(row: r, col: colIndex)) else {
                    isValid = false
                    break
                }
            }
            if isValid {
                validRows.append(r)
            }
        }
        
        guard !validRows.isEmpty else { return }
        
        // Extract Y
        guard let yColIndex = headers.firstIndex(of: dependent) else { return }
        var yData: [Double] = []
        for r in validRows {
            if let val = Double(getCell(row: r, col: yColIndex)) {
                yData.append(val)
            }
        }
        
        // Extract X
        var xData: [[Double]] = []
        for v in independents {
            guard let colIndex = headers.firstIndex(of: v) else { continue }
            var colData: [Double] = []
            for r in validRows {
                if let val = Double(getCell(row: r, col: colIndex)) {
                    colData.append(val)
                }
            }
            xData.append(colData)
        }
        
        linearRegressionResult = statisticsEngine.calculateLinearRegression(y: yData, x: xData)
        linearRegressionDependent = dependent
        linearRegressionIndependents = independents
        linearRegressionOptions = options
        
        // Clear others
        currentStatistics = nil
        correlationResult = nil
        distributionResults = nil
        partialCorrelationResult = nil
        distanceResult = nil
    }
}
