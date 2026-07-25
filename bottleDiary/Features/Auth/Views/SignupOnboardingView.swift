import SwiftUI

// 회원가입 정보를 입력하는 두 번째 온보딩 화면
struct SignupOnboardingView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        OnboardingScaffold(
            title: "회원가입",
            subtitle: "선택한 성별을 바탕으로\n회원가입 정보를 입력해주세요."
        ) {
            VStack(spacing: 18) {
                if let selectedGender = viewModel.selectedGender {
                    Text("선택한 성별: \(selectedGender.rawValue)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: "#BCE3F1"))
                }

                SignupInputWithAction(
                    title: "이메일",
                    text: $viewModel.signupEmail,
                    placeholder: "이메일을 입력하세요",
                    buttonTitle: "중복확인",
                    keyboardType: .emailAddress,
                    action: {
                        Task {
                            await viewModel.checkEmailDuplicate()
                        }
                    }
                )

                if !viewModel.emailCheckMessage.isEmpty {
                    inlineMessage(viewModel.emailCheckMessage)
                }

                LoginInputField(
                    title: "비밀번호",
                    text: $viewModel.signupPassword,
                    placeholder: "비밀번호를 입력하세요",
                    isSecure: true
                )

                SignupInputWithAction(
                    title: "닉네임",
                    text: $viewModel.signupNickname,
                    placeholder: "닉네임을 입력하세요",
                    buttonTitle: "중복확인",
                    action: {
                        Task {
                            await viewModel.checkNicknameDuplicate()
                        }
                    }
                )

                if !viewModel.nicknameCheckMessage.isEmpty {
                    inlineMessage(viewModel.nicknameCheckMessage)
                }

                SignupInputWithAction(
                    title: "전화번호",
                    text: $viewModel.signupPhoneNumber,
                    placeholder: "01012345678",
                    buttonTitle: "인증번호 받기",
                    keyboardType: .numberPad,
                    action: viewModel.requestPhoneVerification
                )

                if !viewModel.phoneCheckMessage.isEmpty {
                    inlineMessage(viewModel.phoneCheckMessage)
                }

                Button(viewModel.isSubmittingSignup ? "가입 중..." : "가입하기") {
                    Task {
                        await viewModel.submitSignup()
                    }
                }
                .buttonStyle(FilledPrimaryButtonStyle())
                .disabled(viewModel.isSubmittingSignup)

                if !viewModel.signupMessage.isEmpty {
                    inlineMessage(viewModel.signupMessage)
                }
            }
        }
    }

    // 회원가입 화면 하단 상태 메시지
    private func inlineMessage(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .medium))
            .multilineTextAlignment(.leading)
            .foregroundStyle(.white.opacity(0.82))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 회원가입 화면 미리보기
struct SignupOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = AppViewModel()
        viewModel.selectedGender = .female
        viewModel.onboardingStep = .signup
        return SignupOnboardingView(viewModel: viewModel)
            .previewDevice("iPhone 16 Pro")
    }
}
