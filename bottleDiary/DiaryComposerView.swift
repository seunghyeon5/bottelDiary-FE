import SwiftUI

// 새 일기를 작성하는 시트 화면
struct DiaryComposerView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("🕯️")
                            .font(.system(size: 42))
                        Spacer()
                        Text("매칭")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.65))
                            .clipShape(Capsule())
                    }

                    Text("오늘 늘 내용이 메모로 적힌다면?")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.65))

                    TextField("제목", text: $viewModel.draftTitle)
                        .font(.title3.weight(.semibold))

                    ZStack(alignment: .topLeading) {
                        if viewModel.draftContent.isEmpty {
                            Text("오늘 당신의 하루는 어땠나요?")
                                .foregroundStyle(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }

                        TextEditor(text: $viewModel.draftContent)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                    }

                    if !viewModel.diarySaveMessage.isEmpty {
                        Text(viewModel.diarySaveMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.65))
                    }
                }
                .padding(20)
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button(viewModel.isSubmittingDiary ? "저장 중..." : "완료") {
                        Task {
                            let didSave = await viewModel.saveDiary()
                            if didSave {
                                dismiss()
                            }
                        }
                    }
                    .font(.footnote.weight(.semibold))
                    .disabled(viewModel.isSubmittingDiary)
                }
            }
        }
    }
}
