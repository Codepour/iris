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
    
    // MARK: - Output Collection
    @Published var outputCollection = OutputCollection()
    
    // MARK: - Pending Results (for popup display before adding to output)
    @Published var pendingCorrelationResult: StatisticsEngine.CorrelationResult?
    @Published var pendingDistributionResults: [DistributionResult]?
    @Published var pendingPartialCorrelationResult: StatisticsEngine.CorrelationResult?
    @Published var pendingLinearRegressionResult: StatisticsEngine.LinearRegressionResult?
    @Published var pendingLinearRegressionDependent: String?
    @Published var pendingLinearRegressionIndependents: [String]?
    @Published var pendingLinearRegressionOptions: LinearRegressionOptions?
    @Published var pendingDistanceResult: [[Double]]?
    @Published var pendingDistanceMetric: StatisticsEngine.DistanceMetric?
    @Published var pendingScatterPlotData: [(x: Double, y: Double)]?
    @Published var pendingScatterPlotXLabel: String = ""
    @Published var pendingScatterPlotYLabel: String = ""
    @Published var pendingScatterPlotTitle: String = ""
    @Published var pendingDescriptiveStatistics: DescriptiveStatistics?
    
    // Flag to show result popup
    @Published var showResultPopup: Bool = false
    @Published var pendingResultType: OutputItemType?
    
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
    private let transformationEngine = TransformationEngine()
    
    func calculateStatisticsForSelection() {
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
            pendingDescriptiveStatistics = statisticsEngine.calculateDescriptiveStatistics(for: numericValues)
            pendingResultType = .descriptiveStatistics
            showResultPopup = true
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
                pendingCorrelationResult = statisticsEngine.calculateCorrelationMatrix(data: cleanData, variables: variables, method: method, testType: testType)
                pendingResultType = .correlation
                showResultPopup = true
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
            
            pendingCorrelationResult = StatisticsEngine.CorrelationResult(matrix: matrix, variables: variables, significant: significant, method: method, controlVariables: nil, testType: testType, n: rowCount)
            pendingResultType = .correlation
            showResultPopup = true
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
        
        pendingDistributionResults = results
        pendingResultType = .distribution
        showResultPopup = true
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
        
        pendingPartialCorrelationResult = statisticsEngine.calculatePartialCorrelations(data: dataMatrix, variables: variables, controls: controls)
        pendingResultType = .partialCorrelation
        showResultPopup = true
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
        
        pendingDistanceResult = distanceResult
        pendingDistanceMetric = metric
        pendingResultType = .distances
        showResultPopup = true
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
        
        pendingLinearRegressionResult = linearRegressionResult
        pendingLinearRegressionDependent = dependent
        pendingLinearRegressionIndependents = independents
        pendingLinearRegressionOptions = options
        pendingResultType = .linearRegression
        showResultPopup = true
    }
    
    // MARK: - Transformations
    
    func getColumnValues(header: String) -> [String] {
        guard let colIndex = headers.firstIndex(of: header) else { return [] }
        return (0..<rowCount).map { getCell(row: $0, col: colIndex) }
    }
    
    func getRowData() -> [[String: String]] {
        var result: [[String: String]] = []
        for r in 0..<rowCount {
            var rowDict: [String: String] = [:]
            for (c, header) in headers.enumerated() {
                rowDict[header] = getCell(row: r, col: c)
            }
            result.append(rowDict)
        }
        return result
    }
    
    func addOrUpdateColumn(header: String, values: [String]) {
        if let colIndex = headers.firstIndex(of: header) {
            // Update existing
            for (r, val) in values.enumerated() {
                if r < rowCount {
                    updateCell(row: r, col: colIndex, value: val)
                }
            }
            // Update type
            detectColumnType(col: colIndex)
        } else {
            // Add new
            let newColIndex = colCount
            headers.append(header)
            colCount += 1
            columnTypes.append(.nominal)
            
            for (r, val) in values.enumerated() {
                if r < rowCount {
                    data.append(Cell(value: val, row: r, col: newColIndex))
                }
            }
            
            // Fill remaining rows if any
            if values.count < rowCount {
                for r in values.count..<rowCount {
                    data.append(Cell(value: "", row: r, col: newColIndex))
                }
            }
            
            detectColumnType(col: newColIndex)
        }
    }
    
    private func detectColumnType(col: Int) {
        let columnValues = data.filter { $0.col == col }.map { $0.value }
        let nonEmptyValues = columnValues.filter { !$0.isEmpty }
        
        if nonEmptyValues.isEmpty {
            columnTypes[col] = .nominal
            return
        }
        
        let isNumeric = nonEmptyValues.allSatisfy { Double($0) != nil }
        columnTypes[col] = isNumeric ? .ratio : .nominal
    }
    
    // Wrapper methods for TransformationEngine
    
    func computeVariable(target: String, rules: [TransformationEngine.ConditionalRule], elseValue: String) {
        let rowData = getRowData()
        let result = transformationEngine.computeNestedIf(data: rowData, rules: rules, elseValue: elseValue)
        addOrUpdateColumn(header: target, values: result)
    }
    
    func recodeVariable(source: String, target: String, method: TransformationEngine.RecodeMethod) {
        let values = getColumnValues(header: source)
        let result = transformationEngine.recode(data: values, method: method)
        addOrUpdateColumn(header: target, values: result)
    }
    
    func standardizeVariable(source: String, target: String, method: TransformationEngine.StandardizationMethod) {
        let values = getColumnValues(header: source)
        
        var numericBuffer = [Double]()
        var indices = [Int]()
        
        for (i, val) in values.enumerated() {
            if let d = Double(val) {
                numericBuffer.append(d)
                indices.append(i)
            }
        }
        
        guard !numericBuffer.isEmpty else { return }
        
        let transformed = transformationEngine.standardize(data: numericBuffer, method: method)
        
        // Create full result column
        var result = [String](repeating: "", count: rowCount)
        
        for (i, val) in transformed.enumerated() {
            let originalIndex = indices[i]
            result[originalIndex] = String(format: "%.4f", val)
        }
        
    }
    
    // MARK: - Chart Builder
    
    @Published var scatterPlotData: [(x: Double, y: Double)]?
    @Published var scatterPlotXLabel: String = ""
    @Published var scatterPlotYLabel: String = ""
    @Published var scatterPlotTitle: String = ""
    
    func runScatterPlot(x: String, y: String, title: String = "") {
        let data = getPairedNumericValues(xHeader: x, yHeader: y)
        scatterPlotData = data
        scatterPlotXLabel = x
        scatterPlotYLabel = y
        scatterPlotTitle = title
        
        pendingScatterPlotData = data
        pendingScatterPlotXLabel = x
        pendingScatterPlotYLabel = y
        pendingScatterPlotTitle = title
        pendingResultType = .scatterPlot
        showResultPopup = true
    }
    
    func getPairedNumericValues(xHeader: String, yHeader: String) -> [(Double, Double)] {
        guard let xCol = headers.firstIndex(of: xHeader),
              let yCol = headers.firstIndex(of: yHeader) else { return [] }
        
        var result: [(Double, Double)] = []
        
        for r in 0..<rowCount {
            if let xVal = Double(getCell(row: r, col: xCol)),
               let yVal = Double(getCell(row: r, col: yCol)) {
                result.append((xVal, yVal))
            }
        }
        
        return result
    }
    
    // MARK: - Output Management
    
    /// Adds the current pending result to the output collection
    func addPendingResultToOutput() {
        guard let resultType = pendingResultType else { return }
        
        switch resultType {
        case .descriptiveStatistics:
            if let stats = pendingDescriptiveStatistics {
                let item = OutputItem(
                    type: .descriptiveStatistics,
                    timestamp: Date(),
                    title: "Descriptive Statistics",
                    data: OutputItem.DescriptiveData(stats: stats)
                )
                outputCollection.addItem(item)
                
                // Also set as current for InspectorView compatibility
                currentStatistics = stats
            }
            
        case .correlation:
            if let result = pendingCorrelationResult {
                let item = OutputItem(
                    type: .correlation,
                    timestamp: Date(),
                    title: "Bivariate Correlation",
                    data: OutputItem.CorrelationData(result: result)
                )
                outputCollection.addItem(item)
                correlationResult = result
            }
            
        case .partialCorrelation:
            if let result = pendingPartialCorrelationResult {
                let item = OutputItem(
                    type: .partialCorrelation,
                    timestamp: Date(),
                    title: "Partial Correlation",
                    data: OutputItem.CorrelationData(result: result)
                )
                outputCollection.addItem(item)
                partialCorrelationResult = result
            }
            
        case .distribution:
            if let results = pendingDistributionResults {
                let item = OutputItem(
                    type: .distribution,
                    timestamp: Date(),
                    title: "Distribution Analysis",
                    data: OutputItem.DistributionData(results: results)
                )
                outputCollection.addItem(item)
                distributionResults = results
            }
            
        case .distances:
            if let matrix = pendingDistanceResult, let metric = pendingDistanceMetric {
                let item = OutputItem(
                    type: .distances,
                    timestamp: Date(),
                    title: "Distance Matrix",
                    data: OutputItem.DistanceData(matrix: matrix, metric: metric)
                )
                outputCollection.addItem(item)
                distanceResult = matrix
                distanceMetric = metric
            }
            
        case .linearRegression:
            if let result = pendingLinearRegressionResult,
               let dependent = pendingLinearRegressionDependent,
               let independents = pendingLinearRegressionIndependents,
               let options = pendingLinearRegressionOptions {
                let item = OutputItem(
                    type: .linearRegression,
                    timestamp: Date(),
                    title: "Linear Regression",
                    data: OutputItem.LinearRegressionData(
                        result: result,
                        dependent: dependent,
                        independents: independents,
                        options: options
                    )
                )
                outputCollection.addItem(item)
                linearRegressionResult = result
                linearRegressionDependent = dependent
                linearRegressionIndependents = independents
                linearRegressionOptions = options
            }
            
        case .scatterPlot:
            if let data = pendingScatterPlotData {
                let item = OutputItem(
                    type: .scatterPlot,
                    timestamp: Date(),
                    title: pendingScatterPlotTitle.isEmpty ? "Scatter Plot" : pendingScatterPlotTitle,
                    data: OutputItem.ScatterPlotData(
                        data: data,
                        title: pendingScatterPlotTitle,
                        xLabel: pendingScatterPlotXLabel,
                        yLabel: pendingScatterPlotYLabel
                    )
                )
                outputCollection.addItem(item)
                scatterPlotData = data
                scatterPlotXLabel = pendingScatterPlotXLabel
                scatterPlotYLabel = pendingScatterPlotYLabel
                scatterPlotTitle = pendingScatterPlotTitle
            }
        }
        
        // Clear pending state
        clearPendingResults()
    }
    
    /// Clears all pending results without adding to output
    func clearPendingResults() {
        pendingCorrelationResult = nil
        pendingDistributionResults = nil
        pendingPartialCorrelationResult = nil
        pendingLinearRegressionResult = nil
        pendingLinearRegressionDependent = nil
        pendingLinearRegressionIndependents = nil
        pendingLinearRegressionOptions = nil
        pendingDistanceResult = nil
        pendingDistanceMetric = nil
        pendingScatterPlotData = nil
        pendingScatterPlotXLabel = ""
        pendingScatterPlotYLabel = ""
        pendingScatterPlotTitle = ""
        pendingDescriptiveStatistics = nil
        pendingResultType = nil
        showResultPopup = false
    }
}
