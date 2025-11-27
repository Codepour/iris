//
//  irisApp.swift
//  iris
//
//  Created by Daniel Szelpal on 2025. 11. 26..
//

import SwiftUI

enum SidebarTool {
    case none
    case correlation
    case partialCorrelation
    case distribution
    case distances
    case linearRegression
}

@main
struct irisApp: App {
    @StateObject private var dataFrame = DataFrame()
    @State private var isImporting: Bool = false
    @State private var activeTool: SidebarTool = .none
    
    var body: some Scene {
        WindowGroup {
            ContentView(dataFrame: dataFrame, isImporting: $isImporting, activeTool: $activeTool)
        }
        .windowToolbarStyle(.unified)
        .commands {
            CommandMenu("Data") {
                Button("Import CSV...") {
                    isImporting = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                
                Button("Import Excel...") {
                    // Placeholder
                }
            }
            
            CommandMenu("Analyze") {
                Button("Descriptive Statistics") {
                    dataFrame.calculateStatisticsForSelection()
                }
                
                Menu("Correlate") {
                    Button("Bivariate...") {
                        activeTool = .correlation
                    }
                    Button("Partial...") {
                        activeTool = .partialCorrelation
                    }
                    Button("Distances...") {
                        activeTool = .distances
                    }
                }
                
                Menu("Distribution") {
                    Button("Univariate...") {
                        activeTool = .distribution
                    }
                }
                
                Menu("Regression") {
                    Button("Linear...") {
                        activeTool = .linearRegression
                    }
                }
            }
            
            CommandMenu("Visualize") {
                Button("Chart Builder") {}
            }
        }
    }
}
