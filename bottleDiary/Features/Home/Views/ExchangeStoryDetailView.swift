import SwiftUI

// 교환된 내 일기와 상대 일기의 상세 내용을 보여주는 화면
struct ExchangeStoryDetailView: View {
    let story: ExchangeStory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        statusHeader
                        diarySection(title: "내 이야기", entry: story.myEntry)
                        Divider()
                        diarySection(title: "다른 이야기", entry: story.partnerEntry)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("교환 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // 교환 상태와 진행 일수를 표시
    private var statusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("익명의 친구와 교환 중")
                    .font(.headline)
                Text("(story.daysRemaining)일째 기록")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(statusText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(statusColor)
                .clipShape(Capsule())
        }
    }

    // 한 사람의 일기 상세 내용을 표시
    private func diarySection(title: String, entry: DiaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color(hex: "#25476D"))
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(entry.dateText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.title)
                        .font(.title3.weight(.semibold))
                }
                Spacer()
                Text(entry.mood)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#25476D"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: "#DCEFFF"))
                    .clipShape(Capsule())
            }
            Text(entry.content)
                .font(.body)
                .foregroundStyle(.black.opacity(0.8))
                .lineSpacing(6)
        }
    }

    private var statusText: String {
        switch story.status {
        case "COMPLETED": return "연결 중"
        case "PENDING": return "답장 대기"
        default: return "연결 종료"
        }
    }

    private var statusColor: Color {
        story.status == "COMPLETED" ? .green : .gray
    }
}
