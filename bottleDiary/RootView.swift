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
        //.dynamicTypeSize(.medium)
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
                        title: "아이디",
                        text: $viewModel.loginId,
                        placeholder: "아이디를 입력하세요"
                    )

                    LoginInputField(
                        title: "비밀번호",
                        text: $viewModel.loginPassword,
                        placeholder: "비밀번호를 입력하세요",
                        isSecure: true
                    )
                }

                Button("로그인") {
                    viewModel.login()
                }
                .buttonStyle(FilledPrimaryButtonStyle())

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
                    action: viewModel.checkEmailDuplicate
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
                    action: viewModel.checkNicknameDuplicate
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

// 일기 목록과 교환 목록을 보여주는 메인 홈 화면
struct MainHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var isPresentingComposer: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "#0A1018"), Color(hex: "#20395C")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabBar
                content
            }

            Button {
                isPresentingComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color(hex: "#A9D5F0"))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
            }
            .padding(.bottom, 28)
        }
    }

    // 메인 화면 상단 헤더 영역
    private var header: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            Spacer()
            if viewModel.selectedTab == .otherStories {
                Text("매칭 중")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(Color.black.opacity(0.22))
    }

    // 내 이야기 / 다른 이야기 전환 탭 영역
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BottleDiaryTab.allCases, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.selectedTab == tab ? .white : .white.opacity(0.6))
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? .white : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // 선택된 탭에 따라 목록을 보여주는 본문 영역
    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .myStories:
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(viewModel.diaryEntries) { diary in
                        DiaryCardView(diary: diary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        case .otherStories:
            if viewModel.exchangeStories.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Text("아직 연결된 사람이 없습니다.")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("당신의 하루를 적어서\n곧 누군가의 하루와 마주해보세요.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                }
                .padding(.bottom, 80)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.exchangeStories) { story in
                            ExchangeCardView(story: story) {
                                viewModel.closeExchange(story)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }
        }
    }
}

// 새 일기를 작성하는 시트 화면
struct DiaryComposerView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("🕯️")
                            .font(.system(size: 42))
                        Spacer()
                        Text("매칭")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.65))
                            .clipShape(Capsule())
                    }

                    Text("오늘 늘 내용이 메모로 적힌다면?")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.65))

                    TextField("제목", text: $viewModel.draftTitle)
                        .font(.title3.weight(.semibold))

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
                    Button("완료") {
                        viewModel.saveDiary()
                        dismiss()
                    }
                    .font(.footnote.weight(.semibold))
                }
            }
        }
    }
}

// 일기 교환이 성사된 뒤 보여주는 결과 화면
struct ExchangeResultView: View {
    let story: ExchangeStory
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#05080D"), Color(hex: "#223E66")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: proxy.size.height < 700 ? 20 : 28) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Spacer()
                        }
                        .foregroundStyle(.white)

                        Spacer(minLength: proxy.size.height < 700 ? 20 : 40)

                        Text("오늘까지\n\(story.daysRemaining)일째 교환이에요")
                            .font(.system(size: proxy.size.height < 700 ? 28 : 34, weight: .bold))
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        Text("“")
                            .font(.system(size: proxy.size.height < 700 ? 40 : 50))
                            .foregroundStyle(.white)

                        Text("각자의 마음을 판단없이\n호기심으로 바라보세요.")
                            .font(.system(size: proxy.size.height < 700 ? 20 : 24, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))

                        Spacer(minLength: proxy.size.height < 700 ? 24 : 40)

                        VStack(spacing: 12) {
                            Button("교환하기") {
                                dismiss()
                            }
                            .buttonStyle(FilledPrimaryButtonStyle())

                            Button("나만 보기") {
                                dismiss()
                            }
                            .buttonStyle(SecondaryFilledButtonStyle())
                        }
                    }
                    .frame(minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
                    .padding(.horizontal, 24)
                    .padding(.top, proxy.safeAreaInsets.top + 22)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 22)
                    //.padding(.vertical, 22)
                }
            }
        }
    }
}

// 공통 온보딩 배경과 레이아웃을 제공하는 래퍼 화면
struct OnboardingScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#03060B"), Color(hex: "#294A75")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            StarFieldView()
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: proxy.size.height < 700 ? 18 : 26) {
                        Spacer(minLength: 0)
                            .frame(height: proxy.size.height < 700 ? 20 : 36)

                        MoonDecorationView()
                            .scaleEffect(proxy.size.height < 700 ? 0.9 : 1)

                        Text(title)
                            .font(.system(size: proxy.size.height < 700 ? 24 : 28, weight: .bold))
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: proxy.size.height < 700 ? 15 : 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .minimumScaleFactor(0.9)

                        Spacer(minLength: 0)
                            .frame(height: proxy.size.height < 700 ? 20 : 46)

                        content

                        Spacer(minLength: proxy.size.height < 700 ? 24 : 40)
                    }
                    .frame(minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
                    .padding(.horizontal, 26)
                    .padding(.top, proxy.safeAreaInsets.top + 12)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 24)
                    //.padding(.vertical, 24)
                }
            }
        }
    }
}

// 로그인 화면에서 사용하는 입력 필드 컴포넌트
struct LoginInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .foregroundStyle(.white)

            Rectangle()
                .fill(.white)
                .frame(height: 1)
        }
    }
}

// 회원가입 화면에서 버튼이 함께 있는 입력 필드 컴포넌트
struct SignupInputWithAction: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let buttonTitle: String
    var keyboardType: UIKeyboardType = .default
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 12) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .foregroundStyle(.white)

                Button(buttonTitle) {
                    action()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#BCE3F1"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }

            Rectangle()
                .fill(.white)
                .frame(height: 1)
        }
    }
}

// 내 이야기 탭에서 사용하는 일기 카드 컴포넌트
struct DiaryCardView: View {
    let diary: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(diary.dateText)
                    .font(.headline)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            Text(diary.title)
                .font(.subheadline.weight(.semibold))
            Text(diary.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// 다른 이야기 탭에서 사용하는 교환 카드 컴포넌트
struct ExchangeCardView: View {
    let story: ExchangeStory
    let disconnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(story.partnerName)와 \(story.daysRemaining)일째")
                    .font(.headline)
                Spacer()
                Button("종료") {
                    disconnect()
                }
                .font(.caption.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("내 이야기")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(story.myEntry.title)
                    .font(.subheadline.weight(.semibold))
                Text(story.myEntry.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("다른 이야기")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(story.partnerEntry.title)
                    .font(.subheadline.weight(.semibold))
                Text(story.partnerEntry.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// 온보딩 상단에 들어가는 달 장식 컴포넌트
struct MoonDecorationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#B6AD6F"))
                .frame(width: 92, height: 92)
                .overlay(alignment: .topLeading) {
                    Circle().fill(Color(hex: "#9D9458")).frame(width: 12, height: 12).offset(x: 22, y: 22)
                }
                .overlay(alignment: .topTrailing) {
                    Circle().fill(Color(hex: "#9D9458")).frame(width: 9, height: 9).offset(x: -28, y: 32)
                }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.gray.opacity(0.55))
                .frame(width: 82, height: 24)
                .offset(x: -26, y: 32)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.gray.opacity(0.7))
                .frame(width: 76, height: 28)
                .offset(x: 16, y: 44)
        }
    }
}

// 배경의 별 장식을 그리는 컴포넌트
struct StarFieldView: View {
    private let stars: [CGPoint] = [
        .init(x: 0.14, y: 0.18), .init(x: 0.27, y: 0.24), .init(x: 0.83, y: 0.28), .init(x: 0.18, y: 0.52),
        .init(x: 0.72, y: 0.58), .init(x: 0.34, y: 0.74), .init(x: 0.62, y: 0.83), .init(x: 0.10, y: 0.88)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(stars.enumerated()), id: \.offset) { index, point in
                Image(systemName: index.isMultiple(of: 2) ? "sparkles" : "circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: index.isMultiple(of: 2) ? 12 : 3, height: index.isMultiple(of: 2) ? 12 : 3)
                    .foregroundStyle(index.isMultiple(of: 2) ? Color(hex: "#D8C969") : .white)
                    .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
            }
        }
    }
}

// 온보딩 선택 버튼 스타일
struct OnboardingOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(configuration.isPressed ? 0.14 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#BCE3F1"), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// 주요 액션에 사용하는 채운 버튼 스타일
struct FilledPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.black.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: "#BCE3F1").opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(Capsule())
    }
}

// 보조 액션에 사용하는 버튼 스타일
struct SecondaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.black.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(configuration.isPressed ? 0.78 : 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// 디자인에서 사용하는 hex 색상 변환 유틸
extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}

// 로그인 화면 미리보기
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AppViewModel())
            .previewDevice("iPhone 16 Pro")
    }
}

// 성별 선택 화면 미리보기
struct GenderOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        GenderOnboardingView(viewModel: AppViewModel())
            .previewDevice("iPhone 16 Pro")
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

// 교환 결과 화면 미리보기
struct ExchangeResultView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeResultView(
            story: ExchangeStory(
                partnerName: "익명의 친구",
                daysRemaining: 3,
                myEntry: DiaryEntry(
                    dateText: "오늘",
                    title: "나의 하루",
                    content: "오늘 일기를 썼다.",
                    mood: "덤덤"
                ),
                partnerEntry: DiaryEntry(
                    dateText: "오늘",
                    title: "상대의 하루",
                    content: "상대방도 조용한 하루를 보냈다.",
                    mood: "덤덤"
                ),
                isActive: true
            ),
            dismiss: {}
        )
        .previewDevice("iPhone 16 Pro")
    }
}
