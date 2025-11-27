import SwiftUI

struct FormulaBarView: View {
    @ObservedObject var dataFrame: DataFrame
    
    var body: some View {
        HStack(spacing: 8) {
            // Address Field
            // Cell Info (Column: Row)
            Text(dataFrame.selectedCellInfo)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(minWidth: 80, alignment: .leading)
                .lineLimit(1)
            
            Divider()
                .frame(height: 20)
            
            // Value Field
            TextField("Value", text: $dataFrame.selectedCellValue)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 20)
            
            // Dataset Statistics
            Text("\(dataFrame.rowCount) rows x \(dataFrame.colCount) variables")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}
