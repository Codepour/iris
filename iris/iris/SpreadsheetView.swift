import SwiftUI

struct SpreadsheetView: View {
    @ObservedObject var dataFrame: DataFrame
    
    var body: some View {
        VStack(spacing: 0) {
            FormulaBarView(dataFrame: dataFrame)
            
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(spacing: 0) {
                    // Header Row
                    HStack(spacing: 0) {
                        Text("#")
                            .frame(width: 40, height: 30)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray.opacity(0.5))
                        
                        ForEach(Array(dataFrame.headers.enumerated()), id: \.element) { index, header in
                            HStack(spacing: 4) {
                                if index < dataFrame.columnTypes.count {
                                    Image(systemName: dataFrame.columnTypes[index].iconName)
                                        .font(.caption2)
                                        .foregroundColor(dataFrame.columnTypes[index].color)
                                }
                                Text(header)
                            }
                            .frame(width: 100, height: 30)
                            .background(Color.gray.opacity(0.2))
                            .border(Color.gray.opacity(0.5))
                            .onTapGesture {
                                dataFrame.selection = .column(index)
                            }
                            .contextMenu {
                                ForEach(MeasureType.allCases, id: \.self) { type in
                                    Button(action: {
                                        dataFrame.updateColumnType(col: index, type: type)
                                    }) {
                                        Label(type.rawValue.capitalized, systemImage: type.iconName)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Data Rows
                    ForEach(0..<dataFrame.rowCount, id: \.self) { row in
                        HStack(spacing: 0) {
                            Text("\(row + 1)")
                                .frame(width: 40, height: 30)
                                .background(Color.gray.opacity(0.1))
                                .border(Color.gray.opacity(0.3))
                                .onTapGesture {
                                    dataFrame.selection = .row(row)
                                }
                            
                            ForEach(0..<dataFrame.colCount, id: \.self) { col in
                                CellView(
                                    row: row,
                                    col: col,
                                    value: dataFrame.getCell(row: row, col: col),
                                    isSelected: dataFrame.isSelected(row: row, col: col),
                                    dataFrame: dataFrame
                                )
                                .equatable()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct CellView: View, Equatable {
    let row: Int
    let col: Int
    let value: String
    let isSelected: Bool
    let dataFrame: DataFrame // Passed as reference for actions
    
    @State private var isEditing: Bool = false
    @State private var isDragging: Bool = false
    
    static func == (lhs: CellView, rhs: CellView) -> Bool {
        return lhs.row == rhs.row &&
               lhs.col == rhs.col &&
               lhs.value == rhs.value &&
               lhs.isSelected == rhs.isSelected
    }
    
    var body: some View {
        ZStack {
            if isEditing {
                TextField("", text: Binding(
                    get: { value },
                    set: { dataFrame.updateCell(row: row, col: col, value: $0) }
                ))
                .textFieldStyle(.plain)
                .padding(4)
                .onSubmit {
                    isEditing = false
                }
            } else {
                Text(value)
                    .lineLimit(1)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
        }
        .frame(width: 100, height: 30)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .border(Color.gray.opacity(0.3))
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    dataFrame.startSelection(row: row, col: col)
                    isEditing = true
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if isEditing { return }
                    
                    if !isDragging {
                        isDragging = true
                        dataFrame.startSelection(row: row, col: col)
                    }
                    
                    // Calculate target cell based on drag translation
                    // Assuming cell size 100x30
                    let colOffset = Int(value.translation.width / 100)
                    let rowOffset = Int(value.translation.height / 30)
                    
                    let targetRow = max(0, min(dataFrame.rowCount - 1, row + rowOffset))
                    let targetCol = max(0, min(dataFrame.colCount - 1, col + colOffset))
                    
                    dataFrame.updateSelection(row: targetRow, col: targetCol)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }
}
