import SwiftUI

// 기존 일기의 제목과 내용을 수정하는 화면
struct DiaryEditorView: View {
    let diary: DiaryEntry
    @ObservedObject var viewModel: AppViewModel
    let onSaved: (DiaryEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String
    @State private var errorMessage = ""
    @State private var isSaving = false

    init(diary: DiaryEntry, viewModel: AppViewModel, onSaved: @escaping (DiaryEntry) -> Void) {
        self.diary = diary
        self.viewModel = viewModel
        self.onSaved = onSaved
        _title = State(initialValue: diary.title)
        _content = State(initialValue: diary.content)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(diary.dateText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.6))

                        TextField("제목", text: $title)
                            .font(.title3.weight(.semibold))
                            .padding(16)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        TextEditor(text: $content)
                            .frame(minHeight: 280)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.red.opacity(0.85))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("일기 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("저장").fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    // 수정 내용을 API로 저장하고 상세 화면에 반영
    private func saveChanges() {
        isSaving = true
        errorMessage = ""
        Task {
            let updatedDiary = await viewModel.updateDiary(diary, title: title, content: content)
            await MainActor.run {
                isSaving = false
                if let updatedDiary {
                    onSaved(updatedDiary)
                    dismiss()
                } else {
                    errorMessage = viewModel.diarySaveMessage
                }
            }
        }
    }
}
