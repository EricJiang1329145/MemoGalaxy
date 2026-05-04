import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \EmotionEntry.timestamp, order: .reverse) private var entries: [EmotionEntry]
    @Environment(\.appLocale) private var locale: Locale

    private var emojiCounts: [(emoji: String, count: Int)] {
        let grouped = Dictionary(grouping: entries, by: \.emotion)
        return grouped.map { ($0.key, $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    private var weeklyCounts: [(week: String, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry -> Date in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.timestamp)
            return calendar.date(from: components) ?? entry.timestamp
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return grouped.map { (formatter.string(from: $0.key), $0.value.count) }
            .sorted { $0.0 < $1.0 }
            .suffix(12)
    }

    var body: some View {
        NavigationStack {
            if entries.isEmpty {
                ContentUnavailableView(
                    l("还没有日记数据"),
                    systemImage: "chart.bar.xaxis",
                    description: Text(l("记录心情后即可查看统计"))
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        emojiDistributionCard
                        weeklyTrendCard
                        recentMoodCard
                    }
                    .padding()
                }
                .navigationTitle(l("心情统计"))
            }
        }
    }

    private var emojiDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l("情绪分布"))
                .font(.headline)

            Chart {
                ForEach(emojiCounts, id: \.emoji) { item in
                    SectorMark(
                        angle: .value("数量", item.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(emojiToColorMap[item.emoji] ?? .gray)
                    .annotation(position: .overlay) {
                        Text(item.emoji)
                            .font(.caption)
                    }
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                ForEach(emojiCounts.prefix(5), id: \.emoji) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(emojiToColorMap[item.emoji] ?? .gray)
                            .frame(width: 8, height: 8)
                        Text("\(item.emoji) \(item.count)")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.1), radius: 4)
        )
    }

    private var weeklyTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l("周趋势（最近12周）"))
                .font(.headline)

            if weeklyCounts.isEmpty {
                Text(l("暂无足够数据"))
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Chart {
                    ForEach(weeklyCounts, id: \.week) { item in
                        BarMark(
                            x: .value("周", item.week),
                            y: .value("篇数", item.count)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.1), radius: 4)
        )
    }

    private var recentMoodCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(l("最近心情"))
                .font(.headline)

            ForEach(entries.prefix(10)) { entry in
                HStack {
                    Text(entry.emotion)
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(entry.title)
                            .font(.subheadline)
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .primary.opacity(0.1), radius: 4)
        )
    }

    private func l(_ key: String) -> String {
        key.localized(locale: locale)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: EmotionEntry.self, inMemory: true)
}