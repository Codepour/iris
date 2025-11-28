import Foundation
import Accelerate

class TransformationEngine {
    
    // MARK: - Compute (If-Then)
    
    enum Operator: String, CaseIterable, Identifiable {
        case equals = "="
        case notEquals = "!="
        case greaterThan = ">"
        case lessThan = "<"
        case greaterThanOrEqual = ">="
        case lessThanOrEqual = "<="
        
        var id: String { rawValue }
    }
    
    struct Condition {
        var variable: String
        var op: Operator
        var value: String // Can be a number or string
    }
    
    func computeIfThen(data: [[String: String]], condition: Condition, trueValue: String, falseValue: String) -> [String] {
        var result: [String] = []
        
        for row in data {
            let val = row[condition.variable] ?? ""
            if evaluate(value: val, condition: condition) {
                result.append(trueValue)
            } else {
                result.append(falseValue)
            }
        }
        
        return result
    }
    
    // Supports nested logic by taking a list of (Condition, Result) pairs and a final Else
    // "If Cond1 Then Res1, Else If Cond2 Then Res2, ... Else FinalRes"
    struct ConditionalRule: Identifiable {
        let id = UUID()
        var condition: Condition
        var result: String
    }
    
    func computeNestedIf(data: [[String: String]], rules: [ConditionalRule], elseValue: String) -> [String] {
        var result: [String] = []
        
        for row in data {
            var matched = false
            for rule in rules {
                let val = row[rule.condition.variable] ?? ""
                if evaluate(value: val, condition: rule.condition) {
                    result.append(rule.result)
                    matched = true
                    break
                }
            }
            
            if !matched {
                result.append(elseValue)
            }
        }
        
        return result
    }
    
    private func evaluate(value: String, condition: Condition) -> Bool {
        // Try numeric comparison first
        if let numVal = Double(value), let numCond = Double(condition.value) {
            switch condition.op {
            case .equals: return numVal == numCond
            case .notEquals: return numVal != numCond
            case .greaterThan: return numVal > numCond
            case .lessThan: return numVal < numCond
            case .greaterThanOrEqual: return numVal >= numCond
            case .lessThanOrEqual: return numVal <= numCond
            }
        }
        
        // Fallback to string comparison
        switch condition.op {
        case .equals: return value == condition.value
        case .notEquals: return value != condition.value
        case .greaterThan: return value > condition.value
        case .lessThan: return value < condition.value
        case .greaterThanOrEqual: return value >= condition.value
        case .lessThanOrEqual: return value <= condition.value
        }
    }
    
    // MARK: - Recode
    
    enum RecodeMethod {
        case specificValue(map: [String: String], elseValue: String?)
        case binning(bins: Int, method: BinningType)
    }
    
    enum BinningType: String, CaseIterable, Identifiable {
        case equalWidth = "Equal Width"
        // case equalFrequency = "Equal Frequency" // TODO: Implement later if needed
        
        var id: String { rawValue }
    }
    
    func recode(data: [String], method: RecodeMethod) -> [String] {
        switch method {
        case .specificValue(let map, let elseValue):
            return data.map { val in
                if let mapped = map[val] {
                    return mapped
                }
                return elseValue ?? val // Keep original if no else value provided
            }
            
        case .binning(let bins, let type):
            guard let numericData = data.compactMap({ Double($0) }) as [Double]?, !numericData.isEmpty else {
                return data // Return original if not numeric
            }
            
            if type == .equalWidth {
                return binEqualWidth(data: data, numericData: numericData, bins: bins)
            }
            return data
        }
    }
    
    private func binEqualWidth(data: [String], numericData: [Double], bins: Int) -> [String] {
        guard let minVal = numericData.min(), let maxVal = numericData.max() else { return data }
        
        let range = maxVal - minVal
        let width = range / Double(bins)
        
        // Pre-calculate bin labels
        var binLabels: [String] = []
        for i in 0..<bins {
            let lower = minVal + Double(i) * width
            let upper = minVal + Double(i + 1) * width
            binLabels.append(String(format: "%.2f - %.2f", lower, upper))
        }
        
        return data.map { valStr in
            guard let val = Double(valStr) else { return "" } // Handle missing/non-numeric
            
            // Find bin
            let binIndex = Int(floor((val - minVal) / width))
            let clampedIndex = max(0, min(binIndex, bins - 1))
            return binLabels[clampedIndex]
        }
    }
    
    // MARK: - Standardize
    
    enum StandardizationMethod: String, CaseIterable, Identifiable {
        case zScore = "Z-Score"
        case minMax = "Min-Max"
        
        var id: String { rawValue }
    }
    
    func standardize(data: [Double], method: StandardizationMethod) -> [Double] {
        guard !data.isEmpty else { return [] }
        let n = vDSP_Length(data.count)
        
        switch method {
        case .zScore:
            var mean: Double = 0
            var stdDev: Double = 0
            var result = [Double](repeating: 0.0, count: data.count)
            
            // vDSP_normalizeD computes (x - mean) / stdDev
            vDSP_normalizeD(data, 1, nil, 1, &mean, &stdDev, n)
            
            // We need to actually perform the calculation since vDSP_normalizeD just returns stats if output is nil?
            // Wait, vDSP_normalizeD documentation: "Vector normalize; double precision."
            // "Calculates the mean and standard deviation of a vector, and then subtracts the mean from the vector and divides by the standard deviation."
            // So if we pass a result buffer, it does it.
            
            vDSP_normalizeD(data, 1, &result, 1, &mean, &stdDev, n)
            return result
            
        case .minMax:
            var minVal: Double = 0
            var maxVal: Double = 0
            vDSP_minvD(data, 1, &minVal, n)
            vDSP_maxvD(data, 1, &maxVal, n)
            
            let range = maxVal - minVal
            if range == 0 { return data.map { _ in 0.0 } }
            
            // (x - min) / (max - min)
            var result = [Double](repeating: 0.0, count: data.count)
            var minNeg = -minVal
            var scale = 1.0 / range
            
            // x - min
            vDSP_vsaddD(data, 1, &minNeg, &result, 1, n)
            // * scale
            vDSP_vsmulD(result, 1, &scale, &result, 1, n)
            
            return result
        }
    }
}
