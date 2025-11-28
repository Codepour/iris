# Iris - Statistical Analysis for macOS

This repository contains **Iris**, a native macOS application for statistical analysis, built with SwiftUI.

## 🤖 Notes for Coding Agents

If you are an AI assistant working on this codebase, please follow these guidelines to ensure consistency, performance, and stability.

### 1. Architecture Overview

*   **`DataModel.swift`**: The heart of the application. It is an `ObservableObject` that holds the `DataFrame` (data), `headers`, analysis results, and the `OutputCollection`.
    *   *Rule*: All major state changes should happen here.
    *   Contains pending result properties for popup display before adding to output.
    *   Contains `addPendingResultToOutput()` and `clearPendingResults()` methods for output management.

*   **`StatisticsEngine.swift`**: Pure logic class for statistical calculations.
    *   *Rule*: Use Apple's **Accelerate** framework (`vDSP`, LAPACK) for all heavy calculations. Do not use manual loops for vector math.

*   **`OutputItem.swift`**: Defines output item types, the `OutputCollection` class, and `OutputSizing` constants.
    *   Contains industry-standard sizing constants based on SPSS/STATA/SAS (600pt standard width).

*   **`OutputCollectionView.swift`**: The main view for the Output tab, displays all added output items.
    *   Replaces the old `InspectorView` as the primary output display.

*   **`ResultViews.swift`**: Contains individual result view components (`CorrelationResultView`, `LinearRegressionResultView`, etc.).

*   **`ResultPopupView.swift`**: Generic popup container for displaying results with "Add to Output" button.

*   **`ContentView.swift`**: The main layout, managing the `NavigationSplitView` and sheet presentations.

### 2. UI/UX Flow (Important!)

#### Config Dialogs (Popup Windows)
*   All analysis configuration (e.g., selecting variables for correlation) is done in **popup windows/sheets**, NOT in the sidebar.
*   Config views are presented using `.sheet()` modifier on `ContentView`.
*   After clicking OK/Run, the config popup closes and the **result popup** appears.

#### Result Popup Flow
1. User runs an analysis from the menu (Analyze > Correlate > Bivariate...)
2. Config popup appears → User configures and clicks OK
3. Config popup closes → Result popup appears showing the output
4. Result popup has two buttons:
   - **Close**: Dismisses without saving (result is discarded)
   - **Add to Output**: Adds the result to the output collection and closes
5. User can navigate to Output View anytime to see collected outputs.

#### Navigation
*   Running a test does **NOT** automatically navigate to the Output view.
*   User decides when to switch to Output View using the segmented control.

### 3. Development Guidelines

#### UI & UX
*   **Native First**: Use standard macOS controls (`List`, `Table`, `Picker`) wherever possible.
*   **Popup Config**: All analysis configurations use popup sheets with consistent sizing (`OutputSizing.configPopupWidth`).
*   **Popup Results**: Results appear in popup first, user decides whether to add to output.
*   **Output View**: Results are collected in `OutputCollectionView`, not displayed immediately in the main view.

#### Output Sizing (Industry Standard)
*   Standard table width: **600 points** (matches SPSS/STATA/SAS conventions)
*   Config popup width: **480 points**
*   Result popup width: **700 points**
*   Use `OutputSizing` constants from `OutputItem.swift` for consistency.

#### Performance
*   **Apple Silicon**: This project targets Apple Silicon. Always prioritize `vDSP` (Vector Digital Signal Processing) over standard Swift arrays for math.
*   **Memory Safety**: When displaying matrices (e.g., Distance Matrix), hard-limit the rendered views to 50-100 items.

### 4. Common Workflows

#### Adding a New Statistical Test
1.  **Logic**: Implement the math in `StatisticsEngine.swift`. Use `vDSP`.
2.  **State**: Add `pending*` result properties in `DataModel.swift` (e.g., `var pendingMyTestResult: MyTestResult?`).
3.  **Run Method**: Create a method that calculates and stores in pending properties, sets `pendingResultType` and `showResultPopup = true`.
4.  **Output Support**: Add case to `OutputItemType` enum and update `addPendingResultToOutput()` in `DataModel`.
5.  **Result View**: Create a result view in `ResultViews.swift`.
6.  **Config UI**: Create a new config View (e.g., `MyTestConfigView.swift`) as a popup.
7.  **ContentView**: Add the config view to `configPopupContent` and result view to `resultContent(for:)`.
8.  **Menu**: Register the tool in `SidebarTool` enum in `irisApp.swift` and add a menu item.

#### File Structure for Analysis Features
```
MyTestConfigView.swift     - Configuration popup
ResultViews.swift          - Add result view component here
OutputItem.swift           - Add OutputItemType case
DataModel.swift            - Add pending properties and run method
ContentView.swift          - Wire up config and result popups
irisApp.swift              - Add menu item and SidebarTool case
```

### 5. Key Files

| File | Purpose |
|------|---------|
| `ContentView.swift` | Main layout, sheet management for popups |
| `DataModel.swift` | Data state, pending results, output collection |
| `OutputItem.swift` | Output types, sizing constants, collection manager |
| `OutputCollectionView.swift` | Output View tab display |
| `ResultPopupView.swift` | Result popup with Add to Output button |
| `ResultViews.swift` | Individual result view components |
| `*ConfigView.swift` | Analysis configuration popups |

### 6. Git & Version Control
*   The `.xcodeproj` is in `iris/`.
*   Always check `git status` before committing.
*   Commit messages should be descriptive (e.g., "Implement Partial Correlation with vDSP").

---
*Created by Antigravity for future iterations.*
