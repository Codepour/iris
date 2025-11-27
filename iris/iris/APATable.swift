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
    var tableNumber: Int? { get }
    var title: String { get }
    var columns: [APAColumn] { get }
    var rows: [APARow] { get }
    var note: String? { get }
}

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
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal)
    }

    private func alignmentFor(_ alignment: APAColumnAlignment) -> Alignment {
        switch alignment {
        case .left:
            return .leading
        case .center, .decimal:
            return .center
        }
    }
}
