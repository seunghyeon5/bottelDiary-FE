import SwiftUI

// 나에게 도착한 답장 대기 일기 목록 화면
struct PendingExchangeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExchange: DiaryExchangeResponsePayload?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                if viewModel.pendingExchanges.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(hex: "#25476D"))
                        Text("답장을 기다리는 일기가 없습니다.")
                            .font(.headline)
                        Text("새로운 일기가 도착하면 이곳에서 확인할 수 있어요.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(24)
                } else {
                    List(viewModel.pendingExchanges) { exchange in
                        Button {
                            selectedExchange = exchange
                        } label: {
                            pendingRow(exchange)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.white.opacity(0.82))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("수신 대기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .sheet(item: $selectedExchange) { exchange in
                PendingExchangeDetailView(exchange: exchange, viewModel: viewModel)
                    .presentationDetents([.large])
            }
            .task {
                await viewModel.loadPendingExchanges()
            }
        }
    }

    // 받은 일기의 요약 정보와 답장 기한을 표시
    private func pendingRow(_ exchange: DiaryExchangeResponsePayload) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exchange.exchangeDate ?? "오늘 도착한 일기")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("답장 대기")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: "#25476D"))
            }
            Text(exchange.partnerDiary?.title ?? exchange.messages?.last?.title ?? "새로운 일기가 도착했습니다")
                .font(.headline)
            Text(exchange.partnerDiary?.content ?? exchange.messages?.last?.content ?? "내용을 확인하고 답장해보세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
    }
}
