import SwiftUI

// 일기 히스토리의 날짜와 기분 필터를 입력하는 화면
struct DiaryFilterView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var fromDate: String
    @State private var toDate: String
    @State private var mood: String
    @State private var isApplying = false

    init(viewModel: AppViewModel) {
        self.viewModel = viewModel
        _fromDate = State(initialValue: viewModel.diaryFromDate)
        _toDate = State(initialValue: viewModel.diaryToDate)
        _mood = State(initialValue: viewModel.diaryMoodFilter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    filterField(title: "시작일", placeholder: "yyyy-MM-dd", text: $fromDate)
                    filterField(title: "종료일", placeholder: "yyyy-MM-dd", text: $toDate)
                    filterField(title: "기분", placeholder: "예: 행복", text: $mood)

                    Button {
                        applyFilters()
                    } label: {
                        Group {
                            if isApplying { ProgressView().tint(.white) }
                            else { Text("필터 적용") }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .foregroundStyle(.white)
                        .background(Color(hex: "#25476D"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isApplying)
                }
                .padding(24)
            }
            .navigationTitle("일기 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("초기화") {
                        fromDate = ""
                        toDate = ""
                        mood = ""
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // 필터 입력 한 줄을 표시
    private func filterField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(14)
                .background(Color.white.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // 입력한 조건으로 서버 히스토리를 다시 조회
    private func applyFilters() {
        isApplying = true
        Task {
            await viewModel.applyDiaryFilters(fromDate: fromDate, toDate: toDate, mood: mood)
            await MainActor.run {
                isApplying = false
                dismiss()
            }
        }
    }
}
