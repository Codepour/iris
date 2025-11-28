import SwiftUI

struct ComputeVariableView: View {
    @ObservedObject var dataFrame: DataFrame
    @Binding var isPresented: Bool
    
    enum Mode: String, CaseIterable, Identifiable {
        case compute = "Compute"
        case recode = "Recode"
        case standardize = "Standardize"
        
        var id: String { rawValue }
    }
    
    @State private var mode: Mode = .compute
    @State private var targetVariable: String = ""
    
    // Compute State
    @State private var computeRules: [TransformationEngine.ConditionalRule] = []
    @State private var computeElseValue: String = ""
    
    // Recode State
    @State private var recodeSourceVariable: String = ""
    @State private var recodeMethod: RecodeMethodType = .binning
    @State private var recodeBins: Int = 3
    @State private var recodeMap: [String: String] = [:] // Simple map for now
    
    enum RecodeMethodType: String, CaseIterable, Identifiable {
        case binning = "Binning (Equal Width)"
        // case specific = "Specific Values" // TODO: Implement UI for map editing
        
        var id: String { rawValue }
    }
    
    // Standardize State
    @State private var standardizeSourceVariable: String = ""
    @State private var standardizeMethod: TransformationEngine.StandardizationMethod = .zScore
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compute Variable")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Configuration Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Configuration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Picker("Operation", selection: $mode) {
                            ForEach(Mode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        TextField("Target Variable Name", text: $targetVariable)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Divider()
                    
                    switch mode {
                    case .compute:
                        computeUI
                    case .recode:
                        recodeUI
                    case .standardize:
                        standardizeUI
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Apply") {
                    apply()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetVariable.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: OutputSizing.configPopupWidth)
        .frame(minHeight: OutputSizing.configPopupMinHeight, maxHeight: OutputSizing.configPopupMaxHeight)
    }
    
    // MARK: - Compute UI
    
    @ViewBuilder
    var computeUI: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Conditions")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(computeRules.indices, id: \.self) { index in
                HStack(alignment: .center) {
                    Text("If")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 15, alignment: .leading)
                    
                    Picker("", selection: $computeRules[index].condition.variable) {
                        Text("Var").tag("")
                        ForEach(dataFrame.headers, id: \.self) { header in
                            Text(header).tag(header)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 90)
                    
                    Picker("", selection: $computeRules[index].condition.op) {
                        ForEach(TransformationEngine.Operator.allCases) { op in
                            Text(op.rawValue).tag(op)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 60)
                    
                    TextField("Val", text: $computeRules[index].condition.value)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    
                    Text("Then")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Res", text: $computeRules[index].result)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    
                    Button(action: { computeRules.remove(at: index) }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Button(action: {
                computeRules.append(TransformationEngine.ConditionalRule(
                    condition: TransformationEngine.Condition(variable: dataFrame.headers.first ?? "", op: .equals, value: ""),
                    result: ""
                ))
            }) {
                Label("Add Condition", systemImage: "plus")
            }
            .padding(.top, 4)
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Default")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                Text("Else")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .leading)
                
                TextField("Result", text: $computeElseValue)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
    
    // MARK: - Recode UI
    
    @ViewBuilder
    var recodeUI: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Variable", selection: $recodeSourceVariable) {
                Text("Select Variable").tag("")
                ForEach(dataFrame.headers, id: \.self) { header in
                    Text(header).tag(header)
                }
            }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Method")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Method", selection: $recodeMethod) {
                ForEach(RecodeMethodType.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.radioGroup)
            
            if recodeMethod == .binning {
                Stepper("Number of Bins: \(recodeBins)", value: $recodeBins, in: 2...20)
            }
        }
    }
    
    // MARK: - Standardize UI
    
    @ViewBuilder
    var standardizeUI: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Variable", selection: $standardizeSourceVariable) {
                Text("Select Variable").tag("")
                ForEach(dataFrame.headers, id: \.self) { header in
                    Text(header).tag(header)
                }
            }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 8) {
            Text("Method")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Method", selection: $standardizeMethod) {
                ForEach(TransformationEngine.StandardizationMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(.radioGroup)
        }
    }
    
    // MARK: - Actions
    
    func apply() {
        switch mode {
        case .compute:
            dataFrame.computeVariable(target: targetVariable, rules: computeRules, elseValue: computeElseValue)
            
        case .recode:
            if !recodeSourceVariable.isEmpty {
                let method: TransformationEngine.RecodeMethod
                switch recodeMethod {
                case .binning:
                    method = .binning(bins: recodeBins, method: .equalWidth)
                }
                dataFrame.recodeVariable(source: recodeSourceVariable, target: targetVariable, method: method)
            }
            
        case .standardize:
            if !standardizeSourceVariable.isEmpty {
                dataFrame.standardizeVariable(source: standardizeSourceVariable, target: targetVariable, method: standardizeMethod)
            }
        }
    }
}
