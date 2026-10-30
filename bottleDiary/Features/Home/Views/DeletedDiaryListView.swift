import SwiftUI

// 삭제 후 24시간 이내에 복구할 수 있는 일기 목록 화면
struct DeletedDiaryListView: View {
    @ObservedObject var viewModel: AppViewModel
    let onSelect: (DeletedDiaryRecovery) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                if viewModel.recoverableDiaries.isEmpty {
                    Text("복구할 수 있는 일기가 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("일기 복구는 24시간 이내에 가능합니다.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(hex: "#25476D"))
                            .padding(.leading, 26)
                        Text("삭제된 일기는 24시간 동안 복구 목록에 보관됩니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 26)

                        List(viewModel.recoverableDiaries) { recovery in
                            Button {
                                onSelect(recovery)
                                dismiss()
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(recovery.dateText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(recovery.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(recovery.content)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.white.opacity(0.82))
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("삭제된 일기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                viewModel.removeExpiredRecoveries()
            }
        }
    }

    // 복구 가능 시간이 얼마나 남았는지 표시
    private func remainingText(for recovery: DeletedDiaryRecovery) -> String {
        let remainingHours = max(0, Int(ceil(recovery.expiresAt.timeIntervalSinceNow / 3600)))
        return "\(remainingHours)시간 내 복구"
    }
}
