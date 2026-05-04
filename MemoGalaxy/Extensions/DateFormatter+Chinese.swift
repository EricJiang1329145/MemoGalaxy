import Foundation

extension DateFormatter {
    static let chineseDate: DateFormatter = makeChineseFormatter("yyyy年MM月dd日")
    static let chineseDateTime: DateFormatter = makeChineseFormatter("yyyy年MM月dd日 HH时mm分ss秒")

    private static func makeChineseFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = format
        return formatter
    }
}
