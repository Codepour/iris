//
//  ContentView.swift
//  iris
//
//  Created by Daniel Szelpal on 2025. 11. 26..
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case data = "Data View"
        case variables = "Variable View"
        case output = "Output View"
        
        var id: String { self.rawValue }
    }
    
    @ObservedObject var dataFrame: DataFrame
    @Binding var isImporting: Bool
    @Binding var activeTool: SidebarTool
    
    @State private var selectedTab: Tab = .data
    @State private var sidebarSelection: String? = "Model Building"
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    // Computed binding for showing config popups
    private var showConfigPopup: Binding<Bool> {
        Binding(
            get: { activeTool != .none },
            set: { if !$0 { activeTool = .none } }
        )
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Simplified sidebar - no config views here anymore
            List(selection: $sidebarSelection) {
                Section("Model Building") {
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Iris")
        } detail: {
            Group {
                switch selectedTab {
                case .data:
                    SpreadsheetView(dataFrame: dataFrame)
                case .variables:
                    Text("Variable View Placeholder")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .output:
                    OutputCollectionView(dataFrame: dataFrame)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("View", selection: $selectedTab) {
                        ForEach(Tab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
            }
        }
        // File importer
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        dataFrame.loadCSV(from: url)
                    }
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        // Config popup sheets
        .sheet(isPresented: showConfigPopup) {
            configPopupContent
        }
        // Result popup sheet
        .sheet(isPresented: $dataFrame.showResultPopup) {
            resultPopupContent
        }
    }
    
    // MARK: - Config Popup Content
    
    @ViewBuilder
    private var configPopupContent: some View {
        switch activeTool {
        case .none:
            EmptyView()
        case .correlation:
            CorrelationConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        case .distribution:
            DistributionConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        case .partialCorrelation:
            PartialCorrelationConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        case .distances:
            DistancesConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        case .linearRegression:
            LinearRegressionConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        case .computeVariable:
            ComputeVariableView(
                dataFrame: dataFrame,
                isPresented: Binding(
                    get: { activeTool == .computeVariable },
                    set: { if !$0 { activeTool = .none } }
                )
            )
        case .chartBuilder:
            ChartBuilderConfigView(
                dataFrame: dataFrame,
                onRun: {
                    activeTool = .none
                },
                onCancel: {
                    activeTool = .none
                }
            )
        }
    }
    
    // MARK: - Result Popup Content
    
    @ViewBuilder
    private var resultPopupContent: some View {
        if let resultType = dataFrame.pendingResultType {
            ResultPopupView(
                title: resultTitle(for: resultType),
                content: {
                    resultContent(for: resultType)
                },
                onAddToOutput: {
                    dataFrame.addPendingResultToOutput()
                },
                onDismiss: {
                    dataFrame.clearPendingResults()
                }
            )
        } else {
            EmptyView()
        }
    }
    
    private func resultTitle(for type: OutputItemType) -> String {
        switch type {
        case .descriptiveStatistics: return "Descriptive Statistics"
        case .correlation: return "Bivariate Correlations"
        case .partialCorrelation: return "Partial Correlations"
        case .distribution: return "Distribution Analysis"
        case .distances: return "Distance Matrix"
        case .linearRegression: return "Linear Regression"
        case .scatterPlot: return "Scatter Plot"
        }
    }
    
    @ViewBuilder
    private func resultContent(for type: OutputItemType) -> some View {
        switch type {
        case .descriptiveStatistics:
            if let stats = dataFrame.pendingDescriptiveStatistics {
                APATableView(data: DescriptiveStatsTable(stats: stats))
                    .frame(width: OutputSizing.standardTableWidth)
            }
        case .correlation:
            if let result = dataFrame.pendingCorrelationResult {
                CorrelationResultView(correlation: result)
                    .frame(width: OutputSizing.standardTableWidth)
            }
        case .partialCorrelation:
            if let result = dataFrame.pendingPartialCorrelationResult {
                PartialCorrelationResultView(partialResult: result)
                    .frame(width: OutputSizing.standardTableWidth)
            }
        case .distribution:
            if let results = dataFrame.pendingDistributionResults {
                DistributionAnalysisView(distributions: results)
                    .frame(width: OutputSizing.standardTableWidth)
            }
        case .distances:
            if let matrix = dataFrame.pendingDistanceResult, let metric = dataFrame.pendingDistanceMetric {
                DistanceResultView(matrix: matrix, metric: metric)
                    .frame(width: OutputSizing.standardTableWidth)
            }
        case .linearRegression:
            if let result = dataFrame.pendingLinearRegressionResult {
                LinearRegressionResultView(
                    regression: result,
                    dependent: dataFrame.pendingLinearRegressionDependent ?? "",
                    independents: dataFrame.pendingLinearRegressionIndependents ?? [],
                    options: dataFrame.pendingLinearRegressionOptions
                )
                .frame(width: OutputSizing.standardTableWidth)
            }
        case .scatterPlot:
            if let data = dataFrame.pendingScatterPlotData {
                ScatterPlotView(
                    data: data,
                    title: dataFrame.pendingScatterPlotTitle,
                    xAxisLabel: dataFrame.pendingScatterPlotXLabel,
                    yAxisLabel: dataFrame.pendingScatterPlotYLabel
                )
                .frame(width: OutputSizing.standardTableWidth, height: 400)
            }
        }
    }
}

#Preview {
    ContentView(dataFrame: DataFrame(), isImporting: .constant(false), activeTool: .constant(.none))
}
