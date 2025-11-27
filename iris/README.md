# Iris - Statistical Analysis for macOS

This repository contains **Iris**, a native macOS application for statistical analysis, built with SwiftUI.

## 🤖 Notes for Coding Agents

If you are an AI assistant working on this codebase, please follow these guidelines to ensure consistency, performance, and stability.

### 1. Architecture Overview

*   **`DataModel.swift`**: The heart of the application. It is an `ObservableObject` that holds the `DataFrame` (data), `headers`, and analysis results (e.g., `correlationResult`, `distributionResults`).
    *   *Rule*: All major state changes should happen here.
*   **`StatisticsEngine.swift`**: Pure logic class for statistical calculations.
    *   *Rule*: Use Apple's **Accelerate** framework (`vDSP`, LAPACK) for all heavy calculations. Do not use manual loops for vector math.
*   **`InspectorView.swift`**: The right-hand sidebar that displays analysis results.
    *   *Rule*: **Never** render massive lists (e.g., >100 rows) directly in SwiftUI. It will crash (`AttributeGraph` failure). Always truncate or use a Canvas/Heatmap.
*   **`ContentView.swift`**: The main layout, managing the `NavigationSplitView`.

### 2. Development Guidelines

#### UI & UX
*   **Native First**: Use standard macOS controls (`List`, `Table`, `Picker`) wherever possible.
*   **Sidebar Config**: Analysis configurations (e.g., selecting variables) should be done in the **Sidebar** (left pane), replacing the file list temporarily. See `PartialCorrelationConfigView.swift` for a reference pattern.
*   **Results**: Results go in the **Inspector** (right pane).

#### Performance
*   **Apple Silicon**: This project targets Apple Silicon. Always prioritize `vDSP` (Vector Digital Signal Processing) over standard Swift arrays for math.
*   **Memory Safety**: When displaying matrices (e.g., Distance Matrix), hard-limit the rendered views to 50-100 items.

### 3. Common Workflows

#### Adding a New Statistical Test
1.  **Logic**: Implement the math in `StatisticsEngine.swift`. Use `vDSP`.
2.  **State**: Add a `@Published` result property in `DataModel.swift` (e.g., `var myTestResult: TestResult?`). Add a method to run it.
3.  **Config UI**: Create a new View (e.g., `MyTestConfigView.swift`) for the sidebar.
4.  **Display**: Update `InspectorView.swift` to check `if let result = dataFrame.myTestResult { ... }` and render it.
5.  **Menu**: Register the tool in `SidebarTool` enum in `irisApp.swift` and add a menu item.

### 4. Git & Version Control
*   The `.xcodeproj` is in `iris/`.
*   Always check `git status` before committing.
*   Commit messages should be descriptive (e.g., "Implement Partial Correlation with vDSP").

---
*Created by Antigravity for future iterations.*
