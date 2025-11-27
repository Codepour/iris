# APA 7th Edition Table Framework for Swift/macOS

## 1. Core Visual Standards (The "Golden Rules")

When generating UI for tables, strict adherence to these rules is required:

### Typography
- **Font**: Use a Serif font for ALL table content: `.font(.system(.body, design: .serif))`
  - Headers: `.font(.system(.body, design: .serif).bold())`
  - Section titles: `.font(.system(.subheadline, design: .serif).bold())`
  - Main title: `.font(.system(.headline, design: .serif).bold())`
  - Notes: `.font(.system(.caption, design: .serif).italic())`
  - Data cells: `.font(.system(.body, design: .serif))`
- **Table Number**: Bold, Left Aligned (e.g., "Table 1")
- **Table Title**: Italic, Title Case, Left Aligned
- **Text Color**: ALL text must be black (`.foregroundColor(.primary)` or default). NEVER use `.foregroundColor(.secondary)` for labels or data

### Borders & Lines (Crucial)
- **Horizontal Rules**: Only THREE mandatory horizontal lines (thickness: 1.5pt):
  1. Top of table (above column headers)
  2. Bottom of column headers (separating headers from data)
  3. Bottom of table (below the last row of data)
- **Implementation**: Use `Rectangle().fill(Color.primary).frame(height: 1.5)`
- **Vertical Lines**: NEVER use vertical lines between columns

### Alignment
- **Stub (First Column)**: Left-aligned
- **Data Columns**: Center-aligned (`.center`) for numeric data
- **Headers**: Center-aligned for data columns, left-aligned for stub column
- **Implementation**: Use `.frame(width: X, alignment: .center)` or `.frame(width: X, alignment: .leading)`

### Spacing
- **Column Spacing**: Consistent 16px between columns
- **Implementation**: Use `.padding(.horizontal, 16)` for center-aligned columns
- **Row Spacing**: Use `.padding(.vertical, 8)` for headers, `.padding(.vertical, 6)` for data rows

### Table Width
- **CRITICAL**: Tables must size to their content, NOT stretch to fill the panel
- **Implementation**: Always add `.fixedSize(horizontal: true, vertical: false)` to the table VStack
- **Column Widths**: Use explicit widths based on content needs:
  - Short labels: 80-100px
  - Medium labels: 120-150px
  - Numeric values: 100px
  - Wide content (CI, etc.): 200px

### Notes
- Placed immediately below the bottom rule
- Prefixed with "Note. " (italicized)
- Font: `.font(.system(.caption, design: .serif).italic())`

## 2. Swift Data Architecture

All statistical tools must output data conforming to this structure rather than building raw Views.

### The Protocol

```swift
import Foundation
import SwiftUI

enum APAColumnAlignment {
    case left
    case center
    case decimal
}

struct APAColumn {
    let id: UUID = UUID()
    let header: String
    let alignment: APAColumnAlignment
    let width: CGFloat?

    init(header: String, alignment: APAColumnAlignment, width: CGFloat? = nil) {
        self.header = header
        self.alignment = alignment
        self.width = width
    }
}

struct APARow: Identifiable {
    let id: UUID = UUID()
    let items: [String]
}

protocol APAReportable {
    var tableNumber: Int? { get }  // Optional for inline tables
    var title: String { get }
    var columns: [APAColumn] { get }
    var rows: [APARow] { get }
    var note: String? { get }
}
```

## 3. SwiftUI Implementation Pattern

### Standard APATableView Structure

```swift
struct APATableView: View {
    let data: APAReportable

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 1. Header Block
            if let tableNumber = data.tableNumber {
                Text("Table \(tableNumber)")
                    .font(.system(.body, design: .serif).bold())
            }

            Text(data.title)
                .font(.system(.body, design: .serif).italic())
                .padding(.bottom, 4)

            // 2. Top Rule
            Rectangle()
                .fill(Color.primary)
                .frame(height: 1.5)

            // 3. Column Headers
            HStack(spacing: 0) {
                ForEach(Array(data.columns.enumerated()), id: \.element.id) { index, column in
                    Text(column.header)
                        .font(.system(.body, design: .serif).bold())
                        .frame(
                            width: column.width,
                            alignment: alignmentFor(column.alignment)
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)

                    if index < data.columns.count - 1 {
                        Spacer(minLength: 16)
                    }
                }
            }

            // 4. Header Separator
            Rectangle()
                .fill(Color.primary)
                .frame(height: 1.5)

            // 5. Data Rows
            ForEach(data.rows) { row in
                HStack(spacing: 0) {
                    ForEach(Array(row.items.enumerated()), id: \.offset) { index, item in
                        if index < data.columns.count {
                            let column = data.columns[index]
                            Text(item)
                                .font(.system(.body, design: .serif))
                                .frame(
                                    width: column.width,
                                    alignment: alignmentFor(column.alignment)
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)

                            if index < data.columns.count - 1 {
                                Spacer(minLength: 16)
                            }
                        }
                    }
                }
            }

            // 6. Bottom Rule
            Rectangle()
                .fill(Color.primary)
                .frame(height: 1.5)

            // 7. Notes
            if let note = data.note {
                Text("Note. \(note)")
                    .font(.system(.caption, design: .serif).italic())
                    .padding(.top, 4)
            }
        }
        .fixedSize(horizontal: true, vertical: false)  // CRITICAL!
        .padding(.horizontal)
    }
}
```

### For Custom/Complex Tables (Correlation Matrices, etc.)

When you need custom table structures that don't fit APAReportable:

```swift
VStack(spacing: 0) {
    // Top border
    Rectangle()
        .fill(Color.primary)
        .frame(height: 1.5)

    // Header Row
    HStack(spacing: 0) {
        Text("Header 1")
            .font(.system(.body, design: .serif).bold())
            .frame(width: 150, alignment: .leading)
            .padding(.leading, 12)
            .padding(.vertical, 8)

        Text("Header 2")
            .font(.system(.body, design: .serif).bold())
            .frame(width: 100, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
    }

    // Header bottom border
    Rectangle()
        .fill(Color.primary)
        .frame(height: 1.5)

    // Data rows
    ForEach(items) { item in
        HStack(spacing: 0) {
            Text(item.label)
                .font(.system(.body, design: .serif))
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 12)
                .padding(.vertical, 6)

            Text(item.value)
                .font(.system(.body, design: .serif))
                .frame(width: 100, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
        }
    }

    // Bottom border
    Rectangle()
        .fill(Color.primary)
        .frame(height: 1.5)
}
.fixedSize(horizontal: true, vertical: false)  // CRITICAL!
.padding(.horizontal)
```

## 4. Number Formatting Rules

### P-values
- **No leading zero**: `.023` not `0.023`
- **Very small values**: `< .001` (not `0.000` or `p < 0.001`)
- **Decimal places**: 3 places
- **Implementation**:
```swift
func formatPValue(_ value: Double) -> String {
    if value < 0.001 {
        return "< .001"
    }
    let formatted = String(format: "%.3f", value)
    if formatted.hasPrefix("0.") {
        return String(formatted.dropFirst())
    }
    return formatted
}
```

### Correlations (r, β)
- **No leading zero**: `.753` not `0.753`
- **Negative values**: `-.359` not `-0.359`
- **Decimal places**: 3 places
- **Implementation**:
```swift
func formatCorrelation(_ value: Double) -> String {
    let formatted = String(format: "%.3f", value)
    if formatted.hasPrefix("0.") {
        return String(formatted.dropFirst())
    } else if formatted.hasPrefix("-0.") {
        return "-" + String(formatted.dropFirst(2))
    }
    return formatted
}
```

### Means, Standard Deviations, Other Statistics
- **Include leading zero**: `0.52` not `.52`
- **Decimal places**: 2 places (standard)
- **Implementation**: `String(format: "%.2f", value)`

### Test Statistics (t, F, etc.)
- **Include leading zero**: Standard formatting
- **Decimal places**: 2 places
- **Implementation**: `String(format: "%.2f", value)`

## 5. Common Table Types & Examples

### Descriptive Statistics
```swift
struct DescriptiveStatsTable: APAReportable {
    let stats: DescriptiveStatistics

    var tableNumber: Int? { nil }
    var title: String { "Descriptive Statistics" }

    var columns: [APAColumn] {
        [
            APAColumn(header: "Statistic", alignment: .left, width: 150),
            APAColumn(header: "Value", alignment: .center, width: 100)
        ]
    }

    var rows: [APARow] {
        var result: [APARow] = []
        result.append(APARow(items: ["Mean", String(format: "%.2f", stats.mean)]))
        result.append(APARow(items: ["SD", String(format: "%.2f", stats.standardDeviation)]))
        // ... more rows
        return result
    }

    var note: String? { nil }
}
```

### Model Summary (Regression)
- **Label column**: 150px, left-aligned
- **Value column**: 100px, center-aligned
- **Statistics**: R, R², Adjusted R², SE
- **Format**: 2 decimal places with leading zeros

### Coefficients Table (Regression)
- **Variable column**: 120px, left-aligned
- **Numeric columns**: 100px (B, SE, β) or 80px (t, p), center-aligned
- **Headers**: Use symbols (B, SE, β, t, p)
- **β and p-values**: No leading zeros
- **Confidence Intervals**: Show as `[lower, upper]` in single column (200px)

### Correlation Matrix
- **Variable names**: 150px columns, left-aligned
- **Correlation values**: 100px minimum, center-aligned
- **Format correlations**: No leading zeros (`.753`)
- **Significance row**: Below each correlation row
- **Note**: Indicate significance level and tail type

## 6. Critical Checklist

Before finalizing any table, verify:

- [ ] All text uses serif font (`.serif`)
- [ ] All text is black (no `.secondary` color)
- [ ] Exactly 3 horizontal rules (top, header separator, bottom)
- [ ] No vertical lines
- [ ] Headers are bold
- [ ] Notes are italic with "Note. " prefix
- [ ] Numeric columns are center-aligned
- [ ] First column (stub) is left-aligned
- [ ] Column spacing is 16px
- [ ] Table has `.fixedSize(horizontal: true, vertical: false)`
- [ ] P-values have no leading zero
- [ ] Correlations/betas have no leading zero
- [ ] Means/SDs have leading zeros
- [ ] All values use appropriate decimal places (2 for most, 3 for p/r)

## 7. Wide Tables

For tables that may exceed panel width:

```swift
ScrollView(.horizontal) {
    VStack(spacing: 0) {
        // ... table content ...
    }
    .fixedSize(horizontal: true, vertical: false)
    .padding(.horizontal)
}
```

This allows horizontal scrolling while maintaining proper table width.
