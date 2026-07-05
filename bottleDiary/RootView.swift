import SwiftUI

// 앱의 전체 화면 분기와 모달 표시를 담당하는 루트 화면
struct RootView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var isPresentingComposer = false

    var body: some View {
        Group {
            switch viewModel.onboardingStep {
            case .login:
                LoginView(viewModel: viewModel)
            case .gender:
                GenderOnboardingView(viewModel: viewModel)
            case .signup:
                SignupOnboardingView(viewModel: viewModel)
            case .completed:
                MainHomeView(viewModel: viewModel, isPresentingComposer: $isPresentingComposer)
            }
        }
        .sheet(isPresented: $isPresentingComposer) {
            DiaryComposerView(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .fullScreenCover(item: $viewModel.latestExchange) { story in
            ExchangeResultView(story: story) {
                viewModel.latestExchange = nil
            }
        }
    }
}
