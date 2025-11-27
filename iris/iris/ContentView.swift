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
        
        var id: String { self.rawValue }
    }
    
    @ObservedObject var dataFrame: DataFrame
    @Binding var isImporting: Bool
    @Binding var activeTool: SidebarTool
    
    @State private var selectedTab: Tab = .data
    @State private var sidebarSelection: String? = "Model Building"
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            Group {
                switch activeTool {
                case .none:
                    List(selection: $sidebarSelection) {
                        Section("Model Building") {
                            Text("Coming Soon")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Iris")
                case .correlation:
                    CorrelationConfigView(
                        dataFrame: dataFrame,
                        onRun: {
                            // Ensure Inspector is visible
                            columnVisibility = .all
                        },
                        onCancel: {
                            activeTool = .none
                        }
                    )
                    .navigationTitle("Correlation")
                case .distribution:
                    DistributionConfigView(
                        dataFrame: dataFrame,
                        onRun: {
                            columnVisibility = .all
                        },
                        onCancel: {
                            activeTool = .none
                        }
                    )
                    .navigationTitle("Distribution")
                case .partialCorrelation:
                    PartialCorrelationConfigView(
                        dataFrame: dataFrame,
                        onRun: {
                            columnVisibility = .all
                        },
                        onCancel: {
                            activeTool = .none
                        }
                    )
                    .navigationTitle("Partial Correlation")
                case .distances:
                    DistancesConfigView(
                        dataFrame: dataFrame,
                        onRun: {
                            columnVisibility = .all
                        },
                        onCancel: {
                            activeTool = .none
                        }
                    )
                    .navigationTitle("Distances")
                case .linearRegression:
                    LinearRegressionConfigView(
                        dataFrame: dataFrame,
                        onRun: {
                            columnVisibility = .all
                        },
                        onCancel: {
                            activeTool = .none
                        }
                    )
                    .navigationTitle("Linear Regression")
                }
            }
        } content: {
            Group {
                switch selectedTab {
                case .data:
                    SpreadsheetView(dataFrame: dataFrame)
                case .variables:
                    Text("Variable View Placeholder")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    .frame(width: 200)
                }
            }
        } detail: {
            InspectorView(dataFrame: dataFrame)
                .navigationSplitViewColumnWidth(min: 300, ideal: 400)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    // Access security scoped resource
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        dataFrame.loadCSV(from: url)
                    }
                }
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    ContentView(dataFrame: DataFrame(), isImporting: .constant(false), activeTool: .constant(.none))
}
