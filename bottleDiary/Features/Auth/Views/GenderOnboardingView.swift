import SwiftUI

// 성별을 선택하는 첫 온보딩 화면
struct GenderOnboardingView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        OnboardingScaffold(title: "성별", subtitle: "당신의 성별은 무엇인가요?") {
            HStack(spacing: 14) {
                ForEach(GenderOption.allCases) { gender in
                    Button(gender.rawValue) {
                        viewModel.selectGender(gender)
                    }
                    .buttonStyle(OnboardingOutlineButtonStyle())
                }
            }
        }
    }
}

// 성별 선택 화면 미리보기
struct GenderOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        GenderOnboardingView(viewModel: AppViewModel())
            .previewDevice("iPhone 16 Pro")
    }
}
