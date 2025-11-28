import SwiftUI

// MARK: - Correlation Result View

struct CorrelationResultView: View {
    let correlation: StatisticsEngine.CorrelationResult
    
    private let stubWidth: CGFloat = OutputSizing.stubColumnWidth
    private let labelWidth: CGFloat = OutputSizing.labelColumnWidth
    private let dataWidth: CGFloat = OutputSizing.wideDataColumnWidth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            APATableTitle("Correlations")
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header Row
                    HStack(spacing: 0) {
                        APAStubCell("", width: stubWidth, isHeader: true)
                        APAStubCell("", width: labelWidth, isHeader: true)
                        
                        ForEach(correlation.variables, id: \.self) { variable in
                            APAHeaderCell(variable, width: dataWidth)
                        }
                    }
                    
                    APATableRule()
                    
                    // Data Rows - grouped by variable
                    ForEach(0..<correlation.variables.count, id: \.self) { i in
                        VStack(spacing: 0) {
                            // Correlation coefficient row
                            HStack(spacing: 0) {
                                APAStubCell(correlation.variables[i], width: stubWidth)
                                APAStubCell(correlation.method == .pearson ? "Pearson Correlation" : "Spearman's rho", width: labelWidth)
                                
                                ForEach(0..<correlation.variables.count, id: \.self) { j in
                                    let value = correlation.matrix[i][j]
                                    let isSig = correlation.significant[i][j]
                                    
                                    APADataCell(
                                        i == j ? "1" : formatCorrelation(value),
                                        width: dataWidth,
                                        bold: isSig && i != j
                                    )
                                }
                            }
                            
                            // Significance row
                            HStack(spacing: 0) {
                                APAStubCell("", width: stubWidth)
                                APAStubCell("Sig. (\(correlation.testType == .twoTailed ? "2" : "1")-tailed)", width: labelWidth)
                                
                                ForEach(0..<correlation.variables.count, id: \.self) { j in
                                    let pValue = i == j ? Double.nan : (correlation.significant[i][j] ? 0.0001 : 0.5)
                                    APADataCell(
                                        i == j ? "" : formatPValue(pValue),
                                        width: dataWidth
                                    )
                                }
                            }
                            
                            // N row
                            HStack(spacing: 0) {
                                APAStubCell("", width: stubWidth)
                                APAStubCell("N", width: labelWidth)
                                
                                ForEach(0..<correlation.variables.count, id: \.self) { _ in
                                    APADataCell("\(correlation.n)", width: dataWidth)
                                }
                            }
                        }
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            
            // Note
            if correlation.significant.flatMap({ $0 }).contains(true) {
                APATableNote("Correlation is significant at the 0.01 level (\(correlation.testType == .twoTailed ? "2" : "1")-tailed).")
            }
        }
    }
}

// MARK: - Partial Correlation Result View

struct PartialCorrelationResultView: View {
    let partialResult: StatisticsEngine.CorrelationResult
    
    private let stubWidth: CGFloat = OutputSizing.stubColumnWidth
    private let labelWidth: CGFloat = OutputSizing.labelColumnWidth
    private let dataWidth: CGFloat = OutputSizing.wideDataColumnWidth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            APATableTitle("Partial Correlations")
            
            // Control Variables info
            if let controls = partialResult.controlVariables, !controls.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Control Variables: \(controls.joined(separator: ", "))")
                        .font(APAFont.body())
                        .italic()
                }
                .padding(.bottom, 8)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header Row
                    HStack(spacing: 0) {
                        APAStubCell("", width: stubWidth, isHeader: true)
                        APAStubCell("", width: labelWidth, isHeader: true)
                        
                        ForEach(partialResult.variables, id: \.self) { variable in
                            APAHeaderCell(variable, width: dataWidth)
                        }
                    }
                    
                    APATableRule()
                    
                    // Data Rows
                    ForEach(0..<partialResult.variables.count, id: \.self) { i in
                        PartialCorrelationRowGroup(
                            partialResult: partialResult,
                            rowIndex: i,
                            stubWidth: stubWidth,
                            labelWidth: labelWidth,
                            dataWidth: dataWidth
                        )
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

/// Helper view for partial correlation data rows
struct PartialCorrelationRowGroup: View {
    let partialResult: StatisticsEngine.CorrelationResult
    let rowIndex: Int
    let stubWidth: CGFloat
    let labelWidth: CGFloat
    let dataWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            // Correlation row
            HStack(spacing: 0) {
                APAStubCell(partialResult.variables[rowIndex], width: stubWidth)
                APAStubCell("Correlation", width: labelWidth)
                
                ForEach(0..<partialResult.variables.count, id: \.self) { j in
                    let value = partialResult.matrix[rowIndex][j]
                    let isSig = partialResult.significant[rowIndex][j]
                    
                    APADataCell(
                        rowIndex == j ? "1" : formatCorrelation(value),
                        width: dataWidth,
                        bold: isSig && rowIndex != j
                    )
                }
            }
            
            // Significance row
            HStack(spacing: 0) {
                APAStubCell("", width: stubWidth)
                APAStubCell("Sig. (\(partialResult.testType == .twoTailed ? "2" : "1")-tailed)", width: labelWidth)
                
                ForEach(0..<partialResult.variables.count, id: \.self) { j in
                    APADataCell(
                        rowIndex == j ? "" : (partialResult.significant[rowIndex][j] ? "< .001" : ""),
                        width: dataWidth
                    )
                }
            }
        }
    }
}

// MARK: - Distance Result View

struct DistanceResultView: View {
    let matrix: [[Double]]
    let metric: StatisticsEngine.DistanceMetric
    
    private let caseWidth: CGFloat = OutputSizing.caseColumnWidth
    private let dataWidth: CGFloat = OutputSizing.dataColumnWidth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            APATableTitle("Proximity Matrix")
            
            Text("Measure: \(metric.rawValue) Distance")
                .font(APAFont.body())
                .italic()
                .padding(.bottom, 4)
            
            let limit = min(matrix.count, 50) // Limit display
            
            if matrix.count > limit {
                APATableNote("Display limited to first \(limit) cases.")
            }
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header Row
                    HStack(spacing: 0) {
                        APAHeaderCell("Case", width: caseWidth, alignment: .center)
                        
                        ForEach(0..<limit, id: \.self) { i in
                            APAHeaderCell("\(i + 1)", width: dataWidth)
                        }
                    }
                    
                    APATableRule()
                    
                    // Data Rows
                    ForEach(0..<limit, id: \.self) { i in
                        HStack(spacing: 0) {
                            APADataCell("\(i + 1)", width: caseWidth, bold: true)
                            
                            ForEach(0..<limit, id: \.self) { j in
                                APADataCell(formatStatistic(matrix[i][j]), width: dataWidth)
                            }
                        }
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxHeight: 400)
        }
    }
}

// MARK: - Linear Regression Result View

struct LinearRegressionResultView: View {
    let regression: StatisticsEngine.LinearRegressionResult
    let dependent: String
    let independents: [String]
    let options: DataFrame.LinearRegressionOptions?
    
    private let stubWidth: CGFloat = OutputSizing.stubColumnWidth
    private let dataWidth: CGFloat = OutputSizing.dataColumnWidth
    private let ciWidth: CGFloat = OutputSizing.ciColumnWidth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            APATableTitle("Regression")
            
            Text("Dependent Variable: \(dependent)")
                .font(APAFont.body())
                .italic()
            
            // Model Summary
            if options?.showModelFit ?? true {
                modelSummaryTable
            }
            
            // Coefficients
            if options?.showEstimates ?? true {
                coefficientsTable
            }
            
            // Residuals
            if options?.showResiduals ?? false {
                residualsTable
            }
        }
    }
    
    // MARK: - Model Summary Table
    
    private var modelSummaryTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Summary")
                .font(APAFont.subtitle())
            
            VStack(spacing: 0) {
                APATableRule()
                
                // Header
                HStack(spacing: 0) {
                    APAHeaderCell("R", width: dataWidth)
                    APAHeaderCell("R²", width: dataWidth)
                    APAHeaderCell("Adjusted R²", width: dataWidth + 20)
                    APAHeaderCell("Std. Error", width: dataWidth + 20)
                }
                
                APATableRule()
                
                // Data
                HStack(spacing: 0) {
                    APADataCell(formatStatistic3(regression.r), width: dataWidth)
                    APADataCell(formatStatistic3(regression.rSquared), width: dataWidth)
                    APADataCell(formatStatistic3(regression.adjustedRSquared), width: dataWidth + 20)
                    APADataCell(formatStatistic(regression.stdErrorEstimate), width: dataWidth + 20)
                }
                
                APATableRule()
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }
    
    // MARK: - Coefficients Table
    
    private var coefficientsTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Coefficients")
                .font(APAFont.subtitle())
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header
                    HStack(spacing: 0) {
                        APAStubCell("", width: stubWidth, isHeader: true)
                        APAHeaderCell("B", width: dataWidth)
                        APAHeaderCell("Std. Error", width: dataWidth + 10)
                        APAHeaderCell("β", width: dataWidth)
                        APAHeaderCell("t", width: dataWidth)
                        APAHeaderCell("Sig.", width: dataWidth)
                        
                        if options?.showConfidenceIntervals ?? false {
                            APAHeaderCell("95% CI", width: ciWidth)
                        }
                    }
                    
                    APATableRule()
                    
                    // Constant row
                    coefficientRow(
                        name: "(Constant)",
                        b: regression.coefficients[0],
                        se: regression.stdErrors[0],
                        beta: nil,
                        t: regression.tStats[0],
                        p: regression.pValues[0],
                        ci: (options?.showConfidenceIntervals ?? false) ? regression.confidenceIntervals[0] : nil
                    )
                    
                    // Variable rows
                    ForEach(0..<independents.count, id: \.self) { i in
                        coefficientRow(
                            name: independents[i],
                            b: regression.coefficients[i + 1],
                            se: regression.stdErrors[i + 1],
                            beta: regression.beta[i + 1],
                            t: regression.tStats[i + 1],
                            p: regression.pValues[i + 1],
                            ci: (options?.showConfidenceIntervals ?? false) ? regression.confidenceIntervals[i + 1] : nil
                        )
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
    
    private func coefficientRow(
        name: String,
        b: Double,
        se: Double,
        beta: Double?,
        t: Double,
        p: Double,
        ci: (lower: Double, upper: Double)?
    ) -> some View {
        HStack(spacing: 0) {
            APAStubCell(name, width: stubWidth)
            APADataCell(formatStatistic(b), width: dataWidth)
            APADataCell(formatStatistic(se), width: dataWidth + 10)
            APADataCell(beta != nil ? formatStatistic3(beta!) : "", width: dataWidth)
            APADataCell(formatStatistic(t), width: dataWidth)
            APADataCell(formatPValue(p), width: dataWidth)
            
            if let ci = ci {
                APADataCell("[\(formatStatistic(ci.lower)), \(formatStatistic(ci.upper))]", width: ciWidth)
            }
        }
    }
    
    // MARK: - Residuals Table
    
    private var residualsTable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Residuals Statistics")
                .font(APAFont.subtitle())
            
            let limit = min(regression.residuals.count, 50)
            
            if regression.residuals.count > limit {
                APATableNote("Display limited to first \(limit) cases.")
            }
            
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header
                    HStack(spacing: 0) {
                        APAHeaderCell("Case", width: OutputSizing.caseColumnWidth)
                        APAHeaderCell("Predicted", width: dataWidth + 20)
                        APAHeaderCell("Residual", width: dataWidth + 20)
                    }
                    
                    APATableRule()
                    
                    ForEach(0..<limit, id: \.self) { i in
                        HStack(spacing: 0) {
                            APADataCell("\(i + 1)", width: OutputSizing.caseColumnWidth, bold: true)
                            APADataCell(formatStatistic(regression.predicted[i]), width: dataWidth + 20)
                            APADataCell(formatStatistic(regression.residuals[i]), width: dataWidth + 20)
                        }
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxHeight: 250)
        }
    }
}
