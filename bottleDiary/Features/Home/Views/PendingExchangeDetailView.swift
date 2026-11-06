import SwiftUI

// 받은 일기를 읽고 답장하거나 거절하는 화면
struct PendingExchangeDetailView: View {
    let exchange: DiaryExchangeResponsePayload
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var mood = "담담"
    @State private var isSubmitting = false
    @State private var message = ""
    private let moodOptions = ["기대", "행복", "평온", "담담", "우울", "화남"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("받은 일기")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(exchange.partnerDiary?.title ?? exchange.messages?.last?.title ?? "새로운 일기")
                            .font(.title3.weight(.bold))

                        Text(exchange.partnerDiary?.content ?? exchange.messages?.last?.content ?? "")
                            .foregroundStyle(.black.opacity(0.78))
                            .lineSpacing(5)

                        Divider()

                        Text("답장 작성")
                            .font(.headline)
                        TextField("답장 제목", text: $title)
                            .padding(14)
                            .background(Color.white.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        TextEditor(text: $content)
                            .frame(minHeight: 180)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(Color.white.opacity(0.82))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Picker("기분", selection: $mood) {
                            ForEach(moodOptions, id: \.self) { Text($0).tag($0) }
                        }
                        .pickerStyle(.menu)

                        if !message.isEmpty {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("일기 답장")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("거절") { reject() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmitting ? "전송 중..." : "답장 보내기") { reply() }
                        .fontWeight(.semibold)
                        .disabled(isSubmitting)
                }
            }
        }
    }

    // 답장 API를 호출
    private func reply() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedContent.isEmpty else {
            message = "답장 제목과 내용을 입력해주세요."
            return
        }
        guard let exchangeId = exchange.exchangeId else { return }
        isSubmitting = true
        Task {
            let success = await viewModel.replyToPending(exchangeId: exchangeId, title: trimmedTitle, content: trimmedContent, mood: mood)
            await MainActor.run {
                isSubmitting = false
                if success { dismiss() }
                else { message = viewModel.diarySaveMessage }
            }
        }
    }

    // 거절 API를 호출
    private func reject() {
        guard let exchangeId = exchange.exchangeId else { return }
        isSubmitting = true
        Task {
            let success = await viewModel.rejectPending(exchangeId: exchangeId)
            await MainActor.run {
                isSubmitting = false
                if success { dismiss() }
                else { message = viewModel.diarySaveMessage }
            }
        }
    }
}
