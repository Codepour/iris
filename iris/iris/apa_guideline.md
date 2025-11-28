# APA 7th Edition Table Standards for Iris

This document defines the table formatting standards used in Iris, based on APA 7th Edition guidelines.

## Quick Reference

### Use the Component Library
All tables should use the components from `APATableComponents.swift`:
- `APAFont` - Consistent font styling
- `APATableRule` - Horizontal border lines
- `APAHeaderCell` - Column header cells
- `APADataCell` - Data value cells
- `APAStubCell` - Row label cells (left-aligned)
- `APATableTitle` - Table titles
- `APATableNote` - Table footnotes

### Font Sizes (APAFont)
| Element | Size | Weight | Design |
|---------|------|--------|--------|
| Title | 13pt | Bold | Serif |
| Subtitle | 12pt | Bold | Serif |
| Header | 11pt | Bold | Serif |
| Body | 11pt | Regular | Serif |
| Note | 10pt | Regular/Italic | Serif |

### Column Widths (OutputSizing)
| Type | Width | Use Case |
|------|-------|----------|
| stubColumnWidth | 140pt | First column (row labels) |
| labelColumnWidth | 140pt | Secondary labels |
| dataColumnWidth | 80pt | Numeric values |
| wideDataColumnWidth | 100pt | Correlations, percentages |
| ciColumnWidth | 140pt | Confidence intervals |
| caseColumnWidth | 60pt | Case/row numbers |

### Cell Padding
- Horizontal: 8pt
- Vertical (headers): 6pt
- Vertical (data): 5pt

---

## Core APA 7th Edition Rules

### 1. Typography
- **Font Family**: Serif (Times New Roman style) for ALL table content
- **Text Color**: Black only (`.foregroundColor(.primary)`)
- **Never use** `.foregroundColor(.secondary)` in tables

### 2. Borders (Critical!)
Only THREE horizontal lines are allowed:
1. **Top border** - Above column headers
2. **Header separator** - Below column headers  
3. **Bottom border** - Below last data row

**Never use vertical lines between columns.**

Implementation:
```swift
APATableRule()  // Uses Rectangle with 1.5pt height
```

### 3. Alignment
- **Stub column** (row labels): Left-aligned
- **Data columns**: Center-aligned
- **Headers**: Match their column alignment

### 4. Table Structure
```swift
VStack(spacing: 0) {
    APATableRule()           // Top border
    
    HStack(spacing: 0) {     // Header row
        APAStubCell("Label", isHeader: true)
        APAHeaderCell("Value", width: 80)
    }
    
    APATableRule()           // Header separator
    
    // Data rows...
    HStack(spacing: 0) {
        APAStubCell("Row 1")
        APADataCell("1.23", width: 80)
    }
    
    APATableRule()           // Bottom border
}
.fixedSize(horizontal: true, vertical: false)  // CRITICAL!
```

### 5. Table Titles
```swift
APATableTitle("Descriptive Statistics")
// or with table number:
APATableTitle("Correlations", number: 1)
```

### 6. Notes
- Placed immediately below bottom border
- Start with "Note. " (italicized)
```swift
APATableNote("Correlation is significant at the 0.01 level (2-tailed).")
```

---

## Number Formatting

### formatCorrelation(_ value: Double) -> String
- 3 decimal places
- No leading zero (e.g., `.845` not `0.845`)
- Used for: r, β, partial correlations

### formatPValue(_ p: Double) -> String
- If p < .001: returns "< .001"
- Otherwise: 3 decimals, no leading zero
- Used for: significance values

### formatStatistic(_ value: Double) -> String
- 2 decimal places
- Used for: means, SD, B coefficients, t-values

### formatStatistic3(_ value: Double) -> String
- 3 decimal places
- Used for: R, R², adjusted R²

---

## Example: Creating a New Table

```swift
struct MyResultView: View {
    let data: MyResult
    
    private let stubWidth = OutputSizing.stubColumnWidth
    private let dataWidth = OutputSizing.dataColumnWidth
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            APATableTitle("My Analysis Results")
            
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    APATableRule()
                    
                    // Header
                    HStack(spacing: 0) {
                        APAStubCell("Variable", width: stubWidth, isHeader: true)
                        APAHeaderCell("Value", width: dataWidth)
                        APAHeaderCell("Sig.", width: dataWidth)
                    }
                    
                    APATableRule()
                    
                    // Data rows
                    ForEach(data.items) { item in
                        HStack(spacing: 0) {
                            APAStubCell(item.name, width: stubWidth)
                            APADataCell(formatStatistic(item.value), width: dataWidth)
                            APADataCell(formatPValue(item.pValue), width: dataWidth)
                        }
                    }
                    
                    APATableRule()
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            
            if data.hasSignificantResults {
                APATableNote("Significant at p < .05.")
            }
        }
    }
}
```

---

## Common Mistakes to Avoid

1. ❌ Using `.foregroundColor(.secondary)` for any table text
2. ❌ Adding vertical borders between columns
3. ❌ Inconsistent font sizes (mixing .body, .caption, etc.)
4. ❌ Using `.trailing` alignment for numeric data (use `.center`)
5. ❌ Forgetting `.fixedSize(horizontal: true, vertical: false)`
6. ❌ Hard-coding padding values instead of using OutputSizing constants
7. ❌ Using leading zeros in correlations and p-values

---

*Based on APA Publication Manual, 7th Edition (2020)*
