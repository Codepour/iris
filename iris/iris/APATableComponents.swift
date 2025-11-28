import SwiftUI

// MARK: - APA 7th Edition Table Components
// Reusable components for consistent table styling across all output views

/// Standard font for all table content (APA recommends serif fonts like Times New Roman)
struct APAFont {
    /// Table title - Bold, larger
    static func title() -> Font {
        .system(size: 13, weight: .bold, design: .serif)
    }
    
    /// Section subtitle - Bold
    static func subtitle() -> Font {
        .system(size: 12, weight: .bold, design: .serif)
    }
    
    /// Column headers - Bold
    static func header() -> Font {
        .system(size: 11, weight: .bold, design: .serif)
    }
    
    /// Data cells - Regular
    static func body() -> Font {
        .system(size: 11, weight: .regular, design: .serif)
    }
    
    /// Notes - Italic, smaller
    static func note() -> Font {
        .system(size: 10, weight: .regular, design: .serif)
    }
}

/// Horizontal rule for APA tables (only top, header-bottom, and table-bottom)
struct APATableRule: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary)
            .frame(height: OutputSizing.borderThickness)
    }
}

/// Standard header cell for APA tables
struct APAHeaderCell: View {
    let text: String
    let width: CGFloat
    let alignment: Alignment
    
    init(_ text: String, width: CGFloat, alignment: Alignment = .center) {
        self.text = text
        self.width = width
        self.alignment = alignment
    }
    
    var body: some View {
        Text(text)
            .font(APAFont.header())
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, OutputSizing.cellHorizontalPadding)
            .padding(.vertical, OutputSizing.cellVerticalPadding)
    }
}

/// Standard data cell for APA tables
struct APADataCell: View {
    let text: String
    let width: CGFloat
    let alignment: Alignment
    let bold: Bool
    
    init(_ text: String, width: CGFloat, alignment: Alignment = .center, bold: Bool = false) {
        self.text = text
        self.width = width
        self.alignment = alignment
        self.bold = bold
    }
    
    var body: some View {
        Text(text)
            .font(APAFont.body())
            .fontWeight(bold ? .bold : .regular)
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, OutputSizing.cellHorizontalPadding)
            .padding(.vertical, OutputSizing.dataCellVerticalPadding)
    }
}

/// Stub cell (first column, left-aligned label)
struct APAStubCell: View {
    let text: String
    let width: CGFloat
    let isHeader: Bool
    let indentLevel: Int
    
    init(_ text: String, width: CGFloat = OutputSizing.stubColumnWidth, isHeader: Bool = false, indent: Int = 0) {
        self.text = text
        self.width = width
        self.isHeader = isHeader
        self.indentLevel = indent
    }
    
    var body: some View {
        Text(text)
            .font(isHeader ? APAFont.header() : APAFont.body())
            .frame(width: width, alignment: .leading)
            .padding(.leading, OutputSizing.cellHorizontalPadding + CGFloat(indentLevel * 12))
            .padding(.trailing, OutputSizing.cellHorizontalPadding)
            .padding(.vertical, isHeader ? OutputSizing.cellVerticalPadding : OutputSizing.dataCellVerticalPadding)
    }
}

/// Table title following APA format
struct APATableTitle: View {
    let tableNumber: Int?
    let title: String
    
    init(_ title: String, number: Int? = nil) {
        self.title = title
        self.tableNumber = number
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let num = tableNumber {
                Text("Table \(num)")
                    .font(APAFont.subtitle())
            }
            Text(title)
                .font(APAFont.title())
        }
    }
}

/// Table note following APA format
struct APATableNote: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text("Note. \(text)")
            .font(APAFont.note())
            .italic()
            .padding(.top, 4)
    }
}

// MARK: - Formatting Helpers

/// Format correlation coefficient to 3 decimal places, no leading zero
func formatCorrelation(_ value: Double) -> String {
    if value.isNaN { return "" }
    let formatted = String(format: "%.3f", value)
    // Remove leading zero for values between -1 and 1
    if value >= 0 && value < 1 {
        return String(formatted.dropFirst()) // Remove "0" from "0.xxx"
    } else if value > -1 && value < 0 {
        return "-" + String(formatted.dropFirst(2)) // "-0.xxx" -> "-.xxx"
    }
    return formatted
}

/// Format p-value according to APA guidelines
func formatPValue(_ p: Double) -> String {
    if p.isNaN { return "" }
    if p < 0.001 {
        return "< .001"
    } else {
        let formatted = String(format: "%.3f", p)
        // Remove leading zero
        if p < 1 {
            return String(formatted.dropFirst())
        }
        return formatted
    }
}

/// Format general statistic to 2 decimal places
func formatStatistic(_ value: Double) -> String {
    if value.isNaN { return "" }
    return String(format: "%.2f", value)
}

/// Format statistic to 3 decimal places
func formatStatistic3(_ value: Double) -> String {
    if value.isNaN { return "" }
    return String(format: "%.3f", value)
}
