import SwiftUI

// 새 일기를 작성하는 시트 화면
struct DiaryComposerView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    private let moodOptions = ["기대", "행복", "평온", "담담", "우울", "화남"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("🕯️")
                            .font(.system(size: 42))
                    }

                    Text("오늘 늘 내용이 메모로 적힌다면?")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.65))

                    TextField("제목", text: $viewModel.draftTitle)
                        .font(.title3.weight(.semibold))

                    moodSelector

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

    // 오늘의 기분을 선택하는 입력 영역
    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘의 기분")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.65))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moodOptions, id: \.self) { mood in
                        Button {
                            viewModel.draftMood = mood
                        } label: {
                            Text(mood)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(viewModel.draftMood == mood ? .white : Color(hex: "#25476D"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(viewModel.draftMood == mood ? Color(hex: "#25476D") : Color.white.opacity(0.8))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }
}
