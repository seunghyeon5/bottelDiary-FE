import SwiftUI

// 내 이야기 목록에서 선택한 일기의 상세 내용을 보여주는 화면
struct DiaryDetailView: View {
    let diary: DiaryEntry
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var displayedDiary: DiaryEntry
    @State private var isShowingEditor = false
    @State private var isShowingDeleteDialog = false
    @State private var isSubmittingDelete = false
    @State private var actionMessage = ""

    init(diary: DiaryEntry, viewModel: AppViewModel) {
        self.diary = diary
        self.viewModel = viewModel
        _displayedDiary = State(initialValue: diary)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(displayedDiary.dateText)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(Color.black.opacity(0.6))

                                    Text(displayedDiary.title)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.black)
                                }

                                Spacer()

                                Text(displayedDiary.mood)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.65))
                                    .clipShape(Capsule())
                            }

                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(height: 1)

                            Text(displayedDiary.content)
                                .font(.body)
                                .foregroundStyle(.black.opacity(0.82))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(6)

                            if !actionMessage.isEmpty {
                                Text(actionMessage)
                                    .font(.footnote)
                                    .foregroundStyle(Color.red.opacity(0.85))
                            }
                        }
                        .padding(20)
                    }

                    actionBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                    }
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                DiaryEditorView(diary: displayedDiary, viewModel: viewModel) { updatedDiary in
                    displayedDiary = updatedDiary
                }
            }
            .confirmationDialog("이 일기를 삭제할까요?", isPresented: $isShowingDeleteDialog, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    deleteDiary()
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("삭제한 일기는 다시 복구할 수 없습니다.")
            }
        }
    }

    // 상세 화면 하단의 수정/삭제 액션 버튼 영역
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                actionMessage = ""
                isShowingEditor = true
            } label: {
                Text("수정")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#25476D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                isShowingDeleteDialog = true
            } label: {
                Group {
                    if isSubmittingDelete {
                        ProgressView().tint(.white)
                    } else {
                        Text("삭제")
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "#D86A6A"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isSubmittingDelete)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color.white.opacity(0.18))
    }

    // 삭제 API를 호출하고 성공하면 상세 화면을 닫음
    private func deleteDiary() {
        isSubmittingDelete = true
        Task {
            let success = await viewModel.deleteDiary(displayedDiary)
            await MainActor.run {
                isSubmittingDelete = false
                if success {
                    dismiss()
                } else {
                    actionMessage = viewModel.diarySaveMessage
                }
            }
        }
    }
}
