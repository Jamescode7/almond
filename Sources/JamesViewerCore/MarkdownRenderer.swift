import Foundation
import Markdown

public enum MarkdownRenderer {
    public static func render(_ source: String) -> String {
        let document = Document(parsing: source)
        var renderer = HTMLRenderVisitor()
        return renderer.visit(document)
    }
}

private struct HTMLRenderVisitor: MarkupVisitor {
    typealias Result = String

    mutating func defaultVisit(_ markup: Markup) -> String {
        return visitChildren(of: markup)
    }

    private mutating func visitChildren(of markup: Markup) -> String {
        var output = ""
        for child in markup.children {
            output += visit(child)
        }
        return output
    }

    mutating func visitDocument(_ document: Document) -> String {
        return visitChildren(of: document)
    }

    mutating func visitHeading(_ heading: Heading) -> String {
        let level = max(1, min(6, heading.level))
        return "<h\(level)>\(visitChildren(of: heading))</h\(level)>\n"
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        return "<p>\(visitChildren(of: paragraph))</p>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        return "<blockquote>\n\(visitChildren(of: blockQuote))</blockquote>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        return "<hr />\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let escaped = HTMLEscape.escape(codeBlock.code)
        if let language = codeBlock.language?.trimmingCharacters(in: .whitespaces), !language.isEmpty {
            return "<pre><code class=\"language-\(HTMLEscape.escape(language))\">\(escaped)</code></pre>\n"
        }
        return "<pre><code>\(escaped)</code></pre>\n"
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        return html.rawHTML
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        return inlineHTML.rawHTML
    }

    mutating func visitUnorderedList(_ list: UnorderedList) -> String {
        return "<ul>\n\(visitChildren(of: list))</ul>\n"
    }

    mutating func visitOrderedList(_ list: OrderedList) -> String {
        return "<ol>\n\(visitChildren(of: list))</ol>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> String {
        let inner = visitChildren(of: listItem)
        switch listItem.checkbox {
        case .checked:
            return "<li class=\"task-list-item\"><input type=\"checkbox\" checked disabled /> \(inner)</li>\n"
        case .unchecked:
            return "<li class=\"task-list-item\"><input type=\"checkbox\" disabled /> \(inner)</li>\n"
        case nil:
            return "<li>\(inner)</li>\n"
        }
    }

    mutating func visitTable(_ table: Table) -> String {
        let alignments = table.columnAlignments
        var output = "<table>\n"
        output += "<thead>\n"
        output += renderRow(table.head, alignments: alignments, cellTag: "th")
        output += "</thead>\n"
        output += "<tbody>\n"
        for row in table.body.rows {
            output += renderRow(row, alignments: alignments, cellTag: "td")
        }
        output += "</tbody>\n"
        output += "</table>\n"
        return output
    }

    private mutating func renderRow<R: Markup>(_ row: R, alignments: [Table.ColumnAlignment?], cellTag: String) -> String {
        var output = "<tr>\n"
        var columnIndex = 0
        for child in row.children {
            guard let cell = child as? Table.Cell else { continue }
            let align = columnIndex < alignments.count ? alignments[columnIndex] : nil
            output += renderCell(cell, alignment: align, cellTag: cellTag)
            columnIndex += Int(max(1, cell.colspan))
        }
        output += "</tr>\n"
        return output
    }

    private mutating func renderCell(_ cell: Table.Cell, alignment: Table.ColumnAlignment?, cellTag: String) -> String {
        var attributes = ""
        if let alignment = alignment {
            switch alignment {
            case .left: attributes += " align=\"left\""
            case .center: attributes += " align=\"center\""
            case .right: attributes += " align=\"right\""
            }
        }
        if cell.colspan > 1 {
            attributes += " colspan=\"\(cell.colspan)\""
        }
        if cell.rowspan > 1 {
            attributes += " rowspan=\"\(cell.rowspan)\""
        }
        let inner = visitChildren(of: cell)
        return "<\(cellTag)\(attributes)>\(inner)</\(cellTag)>\n"
    }

    mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        return ""  // handled in visitTable
    }

    mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        return ""  // handled in visitTable
    }

    mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        return ""  // handled in visitTable
    }

    mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        return visitChildren(of: tableCell)
    }

    mutating func visitText(_ text: Text) -> String {
        return HTMLEscape.escape(text.string)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        return "<em>\(visitChildren(of: emphasis))</em>"
    }

    mutating func visitStrong(_ strong: Strong) -> String {
        return "<strong>\(visitChildren(of: strong))</strong>"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        return "<del>\(visitChildren(of: strikethrough))</del>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        return "<code>\(HTMLEscape.escape(inlineCode.code))</code>"
    }

    mutating func visitLink(_ link: Link) -> String {
        let destination = HTMLEscape.escapeAttribute(link.destination ?? "")
        let title = link.title.map { " title=\"\(HTMLEscape.escapeAttribute($0))\"" } ?? ""
        return "<a href=\"\(destination)\"\(title)>\(visitChildren(of: link))</a>"
    }

    mutating func visitImage(_ image: Image) -> String {
        let source = HTMLEscape.escapeAttribute(image.source ?? "")
        let title = image.title.map { " title=\"\(HTMLEscape.escapeAttribute($0))\"" } ?? ""
        let altText = plainText(of: image)
        let alt = HTMLEscape.escapeAttribute(altText)
        return "<img src=\"\(source)\" alt=\"\(alt)\"\(title) />"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br />\n"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }

    private func plainText(of markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            if let text = child as? Text {
                result += text.string
            } else if let inlineCode = child as? InlineCode {
                result += inlineCode.code
            } else {
                result += plainText(of: child)
            }
        }
        return result
    }
}

enum HTMLEscape {
    static func escape(_ string: String) -> String {
        var result = ""
        result.reserveCapacity(string.count)
        for character in string {
            switch character {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            case "'": result += "&#39;"
            default: result.append(character)
            }
        }
        return result
    }

    static func escapeAttribute(_ string: String) -> String {
        return escape(string)
    }
}
