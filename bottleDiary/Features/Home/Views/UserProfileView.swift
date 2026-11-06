import SwiftUI

// 로그인 사용자의 마이페이지와 계정 관리 화면
struct UserProfileView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingWithdrawDialog = false
    @State private var isShowingBlockedUsers = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    if let user = viewModel.currentUser {
                        profileRow(title: "이메일", value: user.email ?? "-")
                        profileRow(title: "닉네임", value: user.nickname ?? "-")
                        profileRow(title: "성별", value: user.gender ?? "-")
                        profileRow(title: "전화번호", value: user.phoneNum ?? "-")
                    } else {
                        ProgressView("사용자 정보를 불러오는 중")
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        isShowingBlockedUsers = true
                    } label: {
                        HStack {
                            Text("차단 목록")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: "#25476D"))
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    if !viewModel.accountMessage.isEmpty {
                        Text(viewModel.accountMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Button("로그아웃") {
                        viewModel.logout()
                        dismiss()
                    }
                    .buttonStyle(SecondaryFilledButtonStyle())

                    Button("회원 탈퇴", role: .destructive) {
                        isShowingWithdrawDialog = true
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .navigationTitle("마이페이지")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingBlockedUsers) {
                BlockedUserListView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
            .task {
                await viewModel.loadCurrentUser()
            }
            .confirmationDialog("정말 탈퇴할까요?", isPresented: $isShowingWithdrawDialog, titleVisibility: .visible) {
                Button("탈퇴", role: .destructive) {
                    Task {
                        if await viewModel.withdraw() { dismiss() }
                    }
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("정말 탈퇴하시겠습니까?")
            }
        }
    }

    // 마이페이지의 사용자 정보 한 줄을 표시
    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
