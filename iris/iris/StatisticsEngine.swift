import Foundation
import Accelerate

struct DescriptiveStatistics {
    let count: Int
    let mean: Double
    let median: Double
    let mode: Double?
    let variance: Double
    let standardDeviation: Double
    let range: Double
    let min: Double
    let max: Double
    let skewness: Double
    let kurtosis: Double
    let q1: Double
    let q2: Double
    let q3: Double
    let iqr: Double
}

class StatisticsEngine {
    
    func calculateDescriptiveStatistics(for data: [Double]) -> DescriptiveStatistics? {
        guard !data.isEmpty else { return nil }
        
        let count = data.count
        let n = Double(count)
        
        // Convert to [Double] for vDSP operations (already Double, but ensuring contiguous)
        var values = data
        
        // 1. Min/Max
        var minVal: Double = 0
        var maxVal: Double = 0
        vDSP_minvD(values, 1, &minVal, vDSP_Length(count))
        vDSP_maxvD(values, 1, &maxVal, vDSP_Length(count))
        let range = maxVal - minVal
        
        // 2. Mean
        var meanVal: Double = 0
        vDSP_meanvD(values, 1, &meanVal, vDSP_Length(count))
        
        // 3. Variance & Standard Deviation
        var varianceVal: Double = 0
        var stdDevVal: Double = 0
        
        // Calculate variance manually to ensure sample variance (n-1) vs population (n)
        // vDSP_normalize gives population variance usually, let's be explicit
        var minusMean = [Double](repeating: 0.0, count: count)
        var meanNeg = -meanVal
        vDSP_vsaddD(values, 1, &meanNeg, &minusMean, 1, vDSP_Length(count))
        
        var squaredDiffs = [Double](repeating: 0.0, count: count)
        vDSP_vsqD(minusMean, 1, &squaredDiffs, 1, vDSP_Length(count))
        
        var sumSquaredDiffs: Double = 0
        vDSP_sveD(squaredDiffs, 1, &sumSquaredDiffs, vDSP_Length(count))
        
        if count > 1 {
            varianceVal = sumSquaredDiffs / (n - 1)
        } else {
            varianceVal = 0
        }
        stdDevVal = sqrt(varianceVal)
        
        // 4. Sorting for Median/Quartiles
        values.sort()
        
        // 5. Median (Q2)
        let medianVal = calculatePercentile(sortedData: values, percentile: 0.5)
        
        // 6. Quartiles
        let q1Val = calculatePercentile(sortedData: values, percentile: 0.25)
        let q3Val = calculatePercentile(sortedData: values, percentile: 0.75)
        let iqrVal = q3Val - q1Val
        
        // 7. Mode
        let modeVal = calculateMode(sortedData: values)
        
        // 8. Skewness & Kurtosis (Moments)
        // Skewness = (Sum((x - mean)^3) / n) / stdDev^3
        // Kurtosis = (Sum((x - mean)^4) / n) / stdDev^4 - 3
        
        var cubedDiffs = [Double](repeating: 0.0, count: count)
        var fourthDiffs = [Double](repeating: 0.0, count: count)
        
        // Calculate powers
        for i in 0..<count {
            let diff = minusMean[i]
            cubedDiffs[i] = pow(diff, 3)
            fourthDiffs[i] = pow(diff, 4)
        }
        
        var sumCubed: Double = 0
        vDSP_sveD(cubedDiffs, 1, &sumCubed, vDSP_Length(count))
        
        var sumFourth: Double = 0
        vDSP_sveD(fourthDiffs, 1, &sumFourth, vDSP_Length(count))
        
        var skewnessVal: Double = 0
        var kurtosisVal: Double = 0
        
        if varianceVal > 0 {
            let m3 = sumCubed / n
            let m4 = sumFourth / n
            let s3 = pow(sqrt(sumSquaredDiffs / n), 3) // Use population std dev for moments usually
            let s4 = pow(sqrt(sumSquaredDiffs / n), 4)
            
            skewnessVal = m3 / s3
            kurtosisVal = (m4 / s4) - 3
        }
        
        return DescriptiveStatistics(
            count: count,
            mean: meanVal,
            median: medianVal,
            mode: modeVal,
            variance: varianceVal,
            standardDeviation: stdDevVal,
            range: range,
            min: minVal,
            max: maxVal,
            skewness: skewnessVal,
            kurtosis: kurtosisVal,
            q1: q1Val,
            q2: medianVal,
            q3: q3Val,
            iqr: iqrVal
        )
    }
    
    func calculatePercentile(sortedData: [Double], percentile: Double) -> Double {
        let count = sortedData.count
        if count == 0 { return 0 }
        
        let index = Double(count - 1) * percentile
        let lower = Int(floor(index))
        let upper = Int(ceil(index))
        
        if lower == upper {
            return sortedData[lower]
        }
        
        let fraction = index - Double(lower)
        return sortedData[lower] * (1 - fraction) + sortedData[upper] * fraction
    }
    
    func calculatePercentiles(data: [Double], percentiles: [Double]) -> [Double: Double] {
        guard !data.isEmpty else { return [:] }
        let sortedData = data.sorted()
        var results: [Double: Double] = [:]
        
        for p in percentiles {
            // Ensure p is between 0 and 1
            let normalizedP = max(0.0, min(1.0, p))
            results[p] = calculatePercentile(sortedData: sortedData, percentile: normalizedP)
        }
        return results
    }
    
    func calculateZScores(data: [Double]) -> [Double] {
        guard data.count > 1 else { return Array(repeating: 0.0, count: data.count) }
        
        var meanVal: Double = 0
        var stdDevVal: Double = 0
        
        vDSP_normalizeD(data, 1, nil, 1, &meanVal, &stdDevVal, vDSP_Length(data.count))
        
        // vDSP_normalizeD calculates mean and stdDev, but doesn't return the z-scores directly in a simple way without a buffer
        // Actually, let's do it manually for clarity or use vDSP_normalizeD to fill a buffer
        
        var zScores = [Double](repeating: 0.0, count: data.count)
        // (x - mean) / stdDev
        
        var minusMean = [Double](repeating: 0.0, count: data.count)
        var negMean = -meanVal
        vDSP_vsaddD(data, 1, &negMean, &minusMean, 1, vDSP_Length(data.count))
        
        var oneOverStdDev = 1.0 / stdDevVal
        vDSP_vsmulD(minusMean, 1, &oneOverStdDev, &zScores, 1, vDSP_Length(data.count))
        
        return zScores
    }
    
    func calculateFrequencies(data: [Double], bins: Int) -> (counts: [Int], binEdges: [Double]) {
        guard !data.isEmpty, bins > 0 else { return ([], []) }
        
        var minVal: Double = 0
        var maxVal: Double = 0
        vDSP_minvD(data, 1, &minVal, vDSP_Length(data.count))
        vDSP_maxvD(data, 1, &maxVal, vDSP_Length(data.count))
        
        if minVal == maxVal {
            return ([data.count], [minVal, maxVal])
        }
        
        // Add a small epsilon to maxVal to include it in the last bin
        let range = maxVal - minVal
        let binWidth = range / Double(bins)
        let epsilon = range * 1e-6
        
        var binEdges: [Double] = []
        for i in 0...bins {
            binEdges.append(minVal + Double(i) * binWidth)
        }
        // Ensure last edge covers max
        binEdges[bins] = maxVal + epsilon
        
        var counts = [Int](repeating: 0, count: bins)
        
        for value in data {
            // Find bin index
            let index = Int(floor((value - minVal) / binWidth))
            // Clamp to last bin if exactly max (or slightly above due to float precision)
            let clampedIndex = min(index, bins - 1)
            if clampedIndex >= 0 {
                counts[clampedIndex] += 1
            }
        }
        
        return (counts, binEdges)
    }
    
    private func calculateMode(sortedData: [Double]) -> Double? {
        guard !sortedData.isEmpty else { return nil }
        
        var counts: [Double: Int] = [:]
        var maxCount = 0
        var mode: Double? = nil
        
        for value in sortedData {
            let count = (counts[value] ?? 0) + 1
            counts[value] = count
            
            if count > maxCount {
                maxCount = count
                mode = value
            }
        }
        
        // If all values are unique (count 1), arguably no mode or all are modes.
        // For simplicity, return the first found mode if maxCount > 1
        return maxCount > 1 ? mode : nil
    }
    // MARK: - Correlation
    
    enum CorrelationMethod {
        case pearson
        case spearman
    }
    
    enum SignificanceTestType {
        case twoTailed
        case oneTailed
    }
    
    struct CorrelationResult {
        let matrix: [[Double]]
        let variables: [String]
        let significant: [[Bool]]
        let method: CorrelationMethod
        let controlVariables: [String]?
        let testType: SignificanceTestType
        let n: Int
    }
    
    func calculateCorrelationMatrix(data: [[Double]], variables: [String], method: CorrelationMethod, testType: SignificanceTestType) -> CorrelationResult? {
        guard !data.isEmpty, data.count == variables.count else { return nil }
        let numVars = data.count
        let numSamples = data[0].count
        guard numSamples > 1 else { return nil }
        
        var matrix = Array(repeating: Array(repeating: 0.0, count: numVars), count: numVars)
        var significant = Array(repeating: Array(repeating: false, count: numVars), count: numVars)
        
        // Pre-process data (Rank for Spearman)
        let processedData: [[Double]]
        if method == .spearman {
            processedData = data.map { rankData($0) }
        } else {
            processedData = data
        }
        
        for i in 0..<numVars {
            for j in i..<numVars {
                if i == j {
                    matrix[i][j] = 1.0
                    significant[i][j] = true // Self-correlation is always significant
                } else {
                    let r = calculatePearsonCorrelation(x: processedData[i], y: processedData[j])
                    matrix[i][j] = r
                    matrix[j][i] = r
                    
                    let isSig = isSignificant(r: r, n: numSamples, testType: testType)
                    significant[i][j] = isSig
                    significant[j][i] = isSig
                }
            }
        }
        
        return CorrelationResult(matrix: matrix, variables: variables, significant: significant, method: method, controlVariables: nil, testType: testType, n: numSamples)
    }
    
    func calculatePearsonCorrelation(x: [Double], y: [Double]) -> Double {
        let count = x.count
        guard count == y.count, count > 1 else { return 0     }
    

        
        let xData = x
        let yData = y
        
        var xMean: Double = 0
        var yMean: Double = 0
        vDSP_meanvD(xData, 1, &xMean, vDSP_Length(count))
        vDSP_meanvD(yData, 1, &yMean, vDSP_Length(count))
        
        var xMinusMean = [Double](repeating: 0.0, count: count)
        var yMinusMean = [Double](repeating: 0.0, count: count)
        var negXMean = -xMean
        var negYMean = -yMean
        
        vDSP_vsaddD(xData, 1, &negXMean, &xMinusMean, 1, vDSP_Length(count))
        vDSP_vsaddD(yData, 1, &negYMean, &yMinusMean, 1, vDSP_Length(count))
        
        var xSqDiff = [Double](repeating: 0.0, count: count)
        var ySqDiff = [Double](repeating: 0.0, count: count)
        vDSP_vsqD(xMinusMean, 1, &xSqDiff, 1, vDSP_Length(count))
        vDSP_vsqD(yMinusMean, 1, &ySqDiff, 1, vDSP_Length(count))
        
        var sumXSqDiff: Double = 0
        var sumYSqDiff: Double = 0
        vDSP_sveD(xSqDiff, 1, &sumXSqDiff, vDSP_Length(count))
        vDSP_sveD(ySqDiff, 1, &sumYSqDiff, vDSP_Length(count))
        
        var product = [Double](repeating: 0.0, count: count)
        vDSP_vmulD(xMinusMean, 1, yMinusMean, 1, &product, 1, vDSP_Length(count))
        
        var sumProduct: Double = 0
        vDSP_sveD(product, 1, &sumProduct, vDSP_Length(count))
        
        let denominator = sqrt(sumXSqDiff * sumYSqDiff)
        
        if denominator == 0 { return 0 }
        return sumProduct / denominator
    }
    
    func rankData(_ data: [Double]) -> [Double] {
        let indexed = data.enumerated().map { (index: $0, value: $1) }
        let sorted = indexed.sorted { $0.value < $1.value }
        
        var ranks = [Double](repeating: 0.0, count: data.count)
        var i = 0
        while i < sorted.count {
            var j = i
            while j < sorted.count - 1 && sorted[j].value == sorted[j+1].value {
                j += 1
            }
            
            let rank = Double(i + j + 2) / 2.0 // Average rank for ties (1-based)
            for k in i...j {
                ranks[sorted[k].index] = rank
            }
            i = j + 1
        }
        return ranks
    }
    
    func isSignificant(r: Double, n: Int, testType: SignificanceTestType) -> Bool {
        // Test using t-statistic: t = r * sqrt((n-2)/(1-r^2))
        // Under H0: r=0, this follows a t-distribution with df = n-2

        if abs(r) >= 1.0 { return true } // Perfect correlation
        if n < 3 { return false }

        let df = n - 2
        let t = r * sqrt(Double(df) / (1 - r * r))

        // Get critical value from t-distribution at α = 0.05
        let criticalValue = tCriticalValue(df: df, alpha: 0.05, twoTailed: testType == .twoTailed)

        return abs(t) > criticalValue
    }

    // Approximation of t-distribution critical values at α = 0.05
    private func tCriticalValue(df: Int, alpha: Double, twoTailed: Bool) -> Double {
        let effectiveAlpha = twoTailed ? alpha / 2.0 : alpha

        // For common case of α = 0.05
        if alpha == 0.05 {
            // Approximation using lookup table for common df values
            if twoTailed {
                switch df {
                case 1: return 12.706
                case 2: return 4.303
                case 3: return 3.182
                case 4: return 2.776
                case 5: return 2.571
                case 6: return 2.447
                case 7: return 2.365
                case 8: return 2.306
                case 9: return 2.262
                case 10: return 2.228
                case 11...15: return 2.201 - Double(df - 11) * 0.027
                case 16...20: return 2.120 - Double(df - 16) * 0.018
                case 21...30: return 2.086 - Double(df - 21) * 0.010
                case 31...60: return 2.042 - Double(df - 31) * 0.006
                case 61...120: return 2.000 - Double(df - 61) * 0.003
                default: return 1.96 // For df > 120, approximate as z = 1.96
                }
            } else {
                switch df {
                case 1: return 6.314
                case 2: return 2.920
                case 3: return 2.353
                case 4: return 2.132
                case 5: return 2.015
                case 6: return 1.943
                case 7: return 1.895
                case 8: return 1.860
                case 9: return 1.833
                case 10: return 1.812
                case 11...15: return 1.796 - Double(df - 11) * 0.020
                case 16...20: return 1.746 - Double(df - 16) * 0.013
                case 21...30: return 1.721 - Double(df - 21) * 0.008
                case 31...60: return 1.697 - Double(df - 31) * 0.007
                case 61...120: return 1.671 - Double(df - 61) * 0.004
                default: return 1.645 // For df > 120, approximate as z = 1.645
                }
            }
        }

        // Fallback for other alpha values (using normal approximation)
        return twoTailed ? 1.96 : 1.645
    }
    
    // MARK: - Partial Correlation
    
    func invertMatrix(_ matrix: [[Double]]) -> [[Double]]? {
        let n = matrix.count
        guard n > 0, matrix[0].count == n else { return nil }
        
        var inMatrix = matrix.flatMap { $0 }
        
        // Variables for dgetrf_
        var m_getrf = __CLPK_integer(n)
        var n_getrf = __CLPK_integer(n)
        var lda_getrf = __CLPK_integer(n)
        var pivots = [__CLPK_integer](repeating: 0, count: n)
        var error: __CLPK_integer = 0
        
        // LU Factorization
        dgetrf_(&m_getrf, &n_getrf, &inMatrix, &lda_getrf, &pivots, &error)
        
        if error != 0 { return nil }
        
        // Variables for dgetri_
        var n_getri = __CLPK_integer(n)
        var lda_getri = __CLPK_integer(n)
        var workspace = [Double](repeating: 0.0, count: n)
        var lwork_getri = __CLPK_integer(n)
        
        // Inversion
        dgetri_(&n_getri, &inMatrix, &lda_getri, &pivots, &workspace, &lwork_getri, &error)
        
        if error != 0 { return nil }
        
        // Convert back to [[Double]]
        var result = [[Double]]()
        for i in 0..<n {
            let row = Array(inMatrix[i*n..<(i+1)*n])
            result.append(row)
        }
        return result
    }
    
    func calculatePartialCorrelations(data: [[Double]], variables: [String], controls: [String]) -> CorrelationResult? {
        // 1. Combine all variables (Variables + Controls)
        let allVars = variables + controls
        let allData = data // Assuming data corresponds to allVars in order
        
        // 2. Calculate full correlation matrix
        guard let fullCorr = calculateCorrelationMatrix(data: allData, variables: allVars, method: .pearson, testType: .twoTailed) else { return nil }
        
        // 3. Invert correlation matrix to get Precision Matrix
        guard let precisionMatrix = invertMatrix(fullCorr.matrix) else { return nil }
        
        // 4. Calculate Partial Correlations
        // r_ij.rest = -p_ij / sqrt(p_ii * p_jj)
        
        let n = allVars.count
        var partialMatrix = Array(repeating: Array(repeating: 0.0, count: n), count: n)
        var significant = Array(repeating: Array(repeating: false, count: n), count: n)
        
        // We only care about the first 'variables.count' rows/cols for the result
        let numVars = variables.count
        let numSamples = data[0].count // Assuming all rows have same length
        // Degrees of freedom for partial correlation: n - 2 - k (k = number of controls)
        let df = numSamples - 2 - controls.count
        
        for i in 0..<numVars {
            for j in i..<numVars {
                if i == j {
                    partialMatrix[i][j] = 1.0
                    significant[i][j] = true
                } else {
                    let p_ij = precisionMatrix[i][j]
                    let p_ii = precisionMatrix[i][i]
                    let p_jj = precisionMatrix[j][j]
                    
                    let r = -p_ij / sqrt(p_ii * p_jj)
                    partialMatrix[i][j] = r
                    partialMatrix[j][i] = r
                    
                    // Significance test
                    // t = r * sqrt(df / (1 - r^2))
                    if abs(r) < 1.0 && df > 0 {
                        let t = r * sqrt(Double(df) / (1 - r * r))
                        // Approx critical value for p < 0.05
                        let criticalValue = 1.96
                        let isSig = abs(t) > criticalValue
                        significant[i][j] = isSig
                        significant[j][i] = isSig
                    }
                }
            }
        }
        
        // Extract submatrix for just the variables of interest
        var resultMatrix = [[Double]]()
        var resultSig = [[Bool]]()
        
        for i in 0..<numVars {
            resultMatrix.append(Array(partialMatrix[i][0..<numVars]))
            resultSig.append(Array(significant[i][0..<numVars]))
        }
        
        return CorrelationResult(matrix: resultMatrix, variables: variables, significant: resultSig, method: .pearson, controlVariables: controls, testType: .twoTailed, n: numSamples)
    }
    
    // MARK: - Distances
    
    enum DistanceMetric: String {
        case euclidean = "Euclidean"
        case squaredEuclidean = "Squared Euclidean"
        case manhattan = "Manhattan"
        case chebyshev = "Chebyshev"
    }
    
    func calculateDistances(data: [[Double]], metric: DistanceMetric) -> [[Double]]? {
        // Data is [Variable][Row]. We need distances between Rows (Cases).
        // Transpose to [Row][Variable]
        let numVars = data.count
        guard numVars > 0 else { return nil }
        let numRows = data[0].count
        guard numRows > 0 else { return nil }
        
        var cases = [[Double]]()
        for r in 0..<numRows {
            var rowData = [Double]()
            for c in 0..<numVars {
                rowData.append(data[c][r])
            }
            cases.append(rowData)
        }
        
        var distanceMatrix = Array(repeating: Array(repeating: 0.0, count: numRows), count: numRows)
        
        for i in 0..<numRows {
            for j in i..<numRows {
                if i == j {
                    distanceMatrix[i][j] = 0.0
                } else {
                    let d = calculateDistance(v1: cases[i], v2: cases[j], metric: metric)
                    distanceMatrix[i][j] = d
                    distanceMatrix[j][i] = d
                }
            }
        }
        
        return distanceMatrix
    }
    
    private func calculateDistance(v1: [Double], v2: [Double], metric: DistanceMetric) -> Double {
        let count = v1.count
        guard count == v2.count, count > 0 else { return 0 }
        
        var dist: Double = 0.0
        
        switch metric {
        case .euclidean:
            // sqrt(sum((v1 - v2)^2))
            var sqDist: Double = 0
            vDSP_distancesqD(v1, 1, v2, 1, &sqDist, vDSP_Length(count))
            dist = sqrt(sqDist)
            
        case .squaredEuclidean:
            // sum((v1 - v2)^2)
            vDSP_distancesqD(v1, 1, v2, 1, &dist, vDSP_Length(count))
            
        case .manhattan:
            // sum(|v1 - v2|)
            var diff = [Double](repeating: 0.0, count: count)
            vDSP_vsubD(v2, 1, v1, 1, &diff, 1, vDSP_Length(count)) // v1 - v2
            vDSP_svemgD(diff, 1, &dist, vDSP_Length(count))
            
        case .chebyshev:
            // max(|v1 - v2|)
            var diff = [Double](repeating: 0.0, count: count)
            vDSP_vsubD(v2, 1, v1, 1, &diff, 1, vDSP_Length(count)) // v1 - v2
            vDSP_maxmgvD(diff, 1, &dist, vDSP_Length(count))
        }
        
        return dist
    }
    
    // MARK: - Linear Regression
    
    struct LinearRegressionResult {
        let r: Double
        let rSquared: Double
        let adjustedRSquared: Double
        let stdErrorEstimate: Double
        let coefficients: [Double] // Intercept is first
        let stdErrors: [Double]
        let tStats: [Double]
        let pValues: [Double]
        let beta: [Double] // Standardized coefficients
        let residuals: [Double]
        let predicted: [Double]
        let confidenceIntervals: [(lower: Double, upper: Double)]
    }
    
    func calculateLinearRegression(y: [Double], x: [[Double]]) -> LinearRegressionResult? {
        let n = y.count
        let k = x.count // Number of independent variables
        guard n > 0, k > 0, x[0].count == n else { return nil }
        
        // 1. Prepare Data for LAPACK (Column-Major)
        // Design Matrix X: [1, x1, x2, ...]
        // Dimensions: n rows x (k+1) columns
        
        var designMatrix = [Double]()
        // Column 0: Intercept (all 1s)
        designMatrix.append(contentsOf: Array(repeating: 1.0, count: n))
        
        // Columns 1..k: Independent variables
        for i in 0..<k {
            designMatrix.append(contentsOf: x[i])
        }
        
        // Y Vector
        var yVector = y
        
        // 2. Solve Least Squares using dgels_
        // Minimize ||b - Ax||
        
        var m_gels = __CLPK_integer(n)
        var n_gels = __CLPK_integer(k + 1)
        var nrhs_gels = __CLPK_integer(1)
        var lda_gels = __CLPK_integer(n)
        var ldb_gels = __CLPK_integer(n)
        var work_gels = [Double](repeating: 0.0, count: 1)
        var lwork_gels = __CLPK_integer(-1) // Query optimal size
        var info_gels: __CLPK_integer = 0
        
        var trans: Int8 = 78 // 'N'
        
        // Query workspace
        dgels_(&trans, &m_gels, &n_gels, &nrhs_gels, &designMatrix, &lda_gels, &yVector, &ldb_gels, &work_gels, &lwork_gels, &info_gels)
        
        if info_gels != 0 { return nil }
        
        let optimalWork = Int(work_gels[0])
        work_gels = [Double](repeating: 0.0, count: optimalWork)
        lwork_gels = __CLPK_integer(optimalWork)
        
        // Solve
        // Note: designMatrix is modified/destroyed. yVector is overwritten with solution (coefficients) in first k+1 elements, and residuals in the rest.
        // We need a copy of designMatrix for later calculations (predicted values)
        let designMatrixCopy = designMatrix
        
        dgels_(&trans, &m_gels, &n_gels, &nrhs_gels, &designMatrix, &lda_gels, &yVector, &ldb_gels, &work_gels, &lwork_gels, &info_gels)
        
        if info_gels != 0 { return nil }
        
        // Extract Coefficients (B)
        let coefficients = Array(yVector[0..<(k + 1)])
        
        // 3. Calculate Predicted Values and Residuals
        // y_hat = X * B
        
        var predicted = [Double](repeating: 0.0, count: n)
        for i in 0..<n {
            var yHat = 0.0
            for j in 0..<(k + 1) {
                // designMatrixCopy is column-major: index = j * n + i
                yHat += designMatrixCopy[j * n + i] * coefficients[j]
            }
            predicted[i] = yHat
        }
        
        var residuals = [Double](repeating: 0.0, count: n)
        vDSP_vsubD(predicted, 1, y, 1, &residuals, 1, vDSP_Length(n)) // y - predicted
        
        // 4. Sum of Squares
        var yMean: Double = 0
        vDSP_meanvD(y, 1, &yMean, vDSP_Length(n))
        
        var ssTot: Double = 0
        for val in y {
            ssTot += pow(val - yMean, 2)
        }
        
        var ssRes: Double = 0
        vDSP_distancesqD(residuals, 1, [Double](repeating: 0.0, count: n), 1, &ssRes, vDSP_Length(n))
        
        let ssReg = ssTot - ssRes
        
        // 5. Model Statistics
        let rSquared = ssReg / ssTot
        let r = sqrt(rSquared)
        let dfRes = Double(n - k - 1)
        // let dfReg = Double(k)
        
        let adjustedRSquared = 1 - (1 - rSquared) * (Double(n - 1) / dfRes)
        
        let mse = ssRes / dfRes
        let stdErrorEstimate = sqrt(mse)
        
        // 6. Standard Errors of Coefficients
        // Var(B) = MSE * (X^T X)^-1
        
        var xtx = [Double](repeating: 0.0, count: (k + 1) * (k + 1))
        
        for row in 0..<(k + 1) {
            for col in 0..<(k + 1) {
                var sum: Double = 0
                for i in 0..<n {
                    let val1 = designMatrixCopy[row * n + i]
                    let val2 = designMatrixCopy[col * n + i]
                    sum += val1 * val2
                }
                xtx[col * (k + 1) + row] = sum // Store column-major for inversion
            }
        }
        
        // Invert X^T X
        guard let inverseXtX = invertMatrix(matrixFromColumnMajor(xtx, rows: k+1, cols: k+1)) else { return nil }
        let inverseXtXFlat = inverseXtX.flatMap { $0 }
        
        var stdErrors = [Double]()
        for i in 0..<(k + 1) {
            // Diagonal element i,i
            let diag = inverseXtXFlat[i * (k + 1) + i]
            stdErrors.append(sqrt(mse * diag))
        }
        
        // 7. t-stats, p-values, and Confidence Intervals
        var tStats = [Double]()
        var pValues = [Double]()
        var confidenceIntervals = [(lower: Double, upper: Double)]()
        
        let tCritical = 1.96 // Approx for 95% CI (Normal)
        
        for i in 0..<(k + 1) {
            let t = coefficients[i] / stdErrors[i]
            tStats.append(t)
            
            // p = 2 * (1 - CDF(|t|))
            let p = 2.0 * (1.0 - normalCDF(value: abs(t)))
            pValues.append(p)
            
            // CI
            let margin = tCritical * stdErrors[i]
            confidenceIntervals.append((lower: coefficients[i] - margin, upper: coefficients[i] + margin))
        }
        
        // 8. Standardized Coefficients (Beta)
        var betas = [Double]()
        betas.append(0.0) // Intercept
        
        // Calculate SD of Y
        var yMeanNeg = -yMean
        var yDiff = [Double](repeating: 0.0, count: n)
        vDSP_vsaddD(y, 1, &yMeanNeg, &yDiff, 1, vDSP_Length(n))
        var sumSqY: Double = 0
        vDSP_svesqD(yDiff, 1, &sumSqY, vDSP_Length(n))
        let sdY = sqrt(sumSqY / Double(n - 1))
        
        for i in 0..<k {
            let xCol = x[i]
            var xMean: Double = 0
            vDSP_meanvD(xCol, 1, &xMean, vDSP_Length(n))
            
            var xMeanNeg = -xMean
            var xDiff = [Double](repeating: 0.0, count: n)
            vDSP_vsaddD(xCol, 1, &xMeanNeg, &xDiff, 1, vDSP_Length(n))
            var sumSqX: Double = 0
            vDSP_svesqD(xDiff, 1, &sumSqX, vDSP_Length(n))
            let sdX = sqrt(sumSqX / Double(n - 1))
            
            let beta = coefficients[i + 1] * (sdX / sdY)
            betas.append(beta)
        }
        
        return LinearRegressionResult(
            r: r,
            rSquared: rSquared,
            adjustedRSquared: adjustedRSquared,
            stdErrorEstimate: stdErrorEstimate,
            coefficients: coefficients,
            stdErrors: stdErrors,
            tStats: tStats,
            pValues: pValues,
            beta: betas,
            residuals: residuals,
            predicted: predicted,
            confidenceIntervals: confidenceIntervals
        )
    }
    
    private func matrixFromColumnMajor(_ data: [Double], rows: Int, cols: Int) -> [[Double]] {
        var matrix = [[Double]]()
        for r in 0..<rows {
            var row = [Double]()
            for c in 0..<cols {
                row.append(data[c * rows + r])
            }
            matrix.append(row)
        }
        return matrix
    }
    
    private func normalCDF(value: Double) -> Double {
        return 0.5 * (1 + erf(value / sqrt(2)))
    }
}
