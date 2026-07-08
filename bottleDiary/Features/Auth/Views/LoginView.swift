import SwiftUI

// 앱 첫 진입 시 보여주는 로그인 화면
struct LoginView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        OnboardingScaffold(
            title: "로그인",
            subtitle: "bottleDiary에서 오늘의 마음을\n가볍게 기록하고 교환해보세요."
        ) {
            VStack(spacing: 18) {
                VStack(spacing: 14) {
                    LoginInputField(
                        title: "이메일",
                        text: $viewModel.loginId,
                        placeholder: "이메일을 입력하세요"
                    )

                    LoginInputField(
                        title: "비밀번호",
                        text: $viewModel.loginPassword,
                        placeholder: "비밀번호를 입력하세요",
                        isSecure: true
                    )
                }

                Button(viewModel.isSubmittingLogin ? "로그인 중..." : "로그인") {
                    Task {
                        await viewModel.login()
                    }
                }
                .buttonStyle(FilledPrimaryButtonStyle())
                .disabled(viewModel.isSubmittingLogin)

                if !viewModel.loginMessage.isEmpty {
                    Text(viewModel.loginMessage)
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.82))
                }

                if !viewModel.authNoticeMessage.isEmpty {
                    Text(viewModel.authNoticeMessage)
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(hex: "#BCE3F1"))
                }

                HStack(spacing: 6) {
                    Text("처음이신가요?")
                        .foregroundStyle(.white.opacity(0.7))

                    Button("회원가입") {
                        viewModel.startSignup()
                    }
                    .foregroundStyle(Color(hex: "#BCE3F1"))
                    .font(.system(size: 15, weight: .semibold))
                }
                .font(.system(size: 15, weight: .medium))
            }
        }
    }
}

// 로그인 화면 미리보기
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AppViewModel())
            .previewDevice("iPhone 16 Pro")
    }
}
