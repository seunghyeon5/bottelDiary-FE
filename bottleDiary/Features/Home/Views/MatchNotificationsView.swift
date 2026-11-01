import SwiftUI

// 교환 매칭 알림 목록을 보여주는 화면
struct MatchNotificationsView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                if viewModel.matchNotifications.isEmpty {
                    Text("새로운 교환 알림이 없습니다.")
                        .foregroundStyle(.secondary)
                } else {
                    List(viewModel.matchNotifications) { notification in
                        Button {
                            Task { await viewModel.markNotificationRead(notification) }
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(notification.read ? Color.clear : Color.blue)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 6)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(notification.message ?? "새로운 교환 알림이 도착했습니다.")
                                        .foregroundStyle(.primary)
                                    if let createdAt = notification.createdAt {
                                        Text(createdAt)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.white.opacity(0.8))
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
            .task {
                await viewModel.loadMatchNotifications()
            }
        }
    }
}
