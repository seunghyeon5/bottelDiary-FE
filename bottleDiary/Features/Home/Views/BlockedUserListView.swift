import SwiftUI

// 차단한 사용자를 확인하고 차단을 해제하는 화면
struct BlockedUserListView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                if viewModel.blockedUsers.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 34))
                            .foregroundStyle(Color(hex: "#25476D"))
                        Text("차단한 사용자가 없습니다.")
                            .font(.headline)
                        Text("교환 화면에서 상대를 차단하면 이곳에 표시됩니다.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                } else {
                    List(viewModel.blockedUsers) { blockedUser in
                        HStack {
                            Text(blockedUser.nickname)
                                .font(.body.weight(.semibold))
                            Spacer()
                            Button("차단 해제") {
                                Task {
                                    _ = await viewModel.unblockUser(blockedUser)
                                }
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "#25476D"))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(Color(hex: "#DCEFFF"))
                            .clipShape(Capsule())
                        }
                        .padding(.vertical, 5)
                        .listRowBackground(Color.white.opacity(0.82))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("차단 목록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await viewModel.loadBlockedUsers()
            }
        }
    }
}
