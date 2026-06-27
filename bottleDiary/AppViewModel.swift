import Foundation

// 앱 전체 화면 흐름과 목업 데이터를 관리하는 뷰모델
@MainActor
final class AppViewModel: ObservableObject {
    private let userAPIService = UserAPIService()

    @Published var onboardingStep: OnboardingStep = .login
    @Published var loginId = ""
    @Published var loginPassword = ""
    @Published var selectedGender: GenderOption?
    @Published var signupEmail = ""
    @Published var signupPassword = ""
    @Published var signupNickname = ""
    @Published var signupPhoneNumber = ""
    @Published var authNoticeMessage = ""
    @Published var emailCheckMessage = ""
    @Published var nicknameCheckMessage = ""
    @Published var phoneCheckMessage = ""
    @Published var signupMessage = ""
    @Published var isSubmittingSignup = false
    @Published var selectedTab: BottleDiaryTab = .myStories
    @Published var diaryEntries: [DiaryEntry] = [
        DiaryEntry(dateText: "오늘", title: "오늘도 어느 때보다 다정한 하루", content: "조용한 밤 공기와 따뜻한 대화가 오래 남았어요.", mood: "평온"),
        DiaryEntry(dateText: "어제", title: "작은 용기를 낸 하루", content: "망설이던 연락을 보냈고 생각보다 마음이 편해졌어요.", mood: "설렘"),
        DiaryEntry(dateText: "1.15 수", title: "퇴근길에 별을 본 날", content: "집으로 오는 길에 밤하늘이 유난히 예뻤어요.", mood: "감사")
    ]
    @Published var exchangeStories: [ExchangeStory] = []
    @Published var draftTitle = ""
    @Published var draftContent = ""
    @Published var latestExchange: ExchangeStory?

    // 로그인 입력이 완료되면 메인 화면으로 이동
    func login() {
        let trimmedId = loginId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = loginPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty, !trimmedPassword.isEmpty else { return }
        onboardingStep = .completed
    }

    // 회원가입을 누르면 온보딩 첫 단계로 이동
    func startSignup() {
        authNoticeMessage = ""
        onboardingStep = .gender
    }

    // 성별 선택 후 전화번호 입력 화면으로 이동
    func selectGender(_ gender: GenderOption) {
        selectedGender = gender
        onboardingStep = .signup
    }

    // 이메일 형식과 현재 입력 상태를 확인
    func checkEmailDuplicate() {
        let trimmedEmail = signupEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            emailCheckMessage = "이메일을 입력해주세요."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            emailCheckMessage = "올바른 이메일 형식이 아닙니다."
            return
        }

        emailCheckMessage = "중복확인 전용 API가 없어 가입 시 서버에서 최종 확인됩니다."
    }

    // 닉네임 입력 상태를 확인
    func checkNicknameDuplicate() {
        let trimmedNickname = signupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNickname.isEmpty else {
            nicknameCheckMessage = "닉네임을 입력해주세요."
            return
        }

        guard trimmedNickname.count >= 2 else {
            nicknameCheckMessage = "닉네임은 2자 이상 입력해주세요."
            return
        }

        nicknameCheckMessage = "닉네임 중복확인 API가 없어 가입 시 함께 확인해야 합니다."
    }

    // 전화번호 형식만 우선 확인하고 인증 API 연결 여부를 안내
    func requestPhoneVerification() {
        let trimmedPhone = signupPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPhone.isEmpty else {
            phoneCheckMessage = "전화번호를 입력해주세요."
            return
        }

        phoneCheckMessage = "전화번호 인증 API는 아직 없어 버튼만 먼저 연결했습니다."
    }

    // 회원가입 요청을 서버로 전송
    func submitSignup() async {
        let email = signupEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = signupPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let nickname = signupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneNum = signupPhoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        emailCheckMessage = ""
        nicknameCheckMessage = ""
        phoneCheckMessage = ""
        signupMessage = ""

        guard let selectedGender else {
            signupMessage = "성별을 먼저 선택해주세요."
            return
        }

        guard isValidEmail(email) else {
            emailCheckMessage = "올바른 이메일 형식이 아닙니다."
            return
        }

        guard !password.isEmpty else {
            signupMessage = "비밀번호를 입력해주세요."
            return
        }

        guard !nickname.isEmpty else {
            nicknameCheckMessage = "닉네임을 입력해주세요."
            return
        }

        guard !phoneNum.isEmpty else {
            phoneCheckMessage = "전화번호를 입력해주세요."
            return
        }

        isSubmittingSignup = true
        defer { isSubmittingSignup = false }

        do {
            _ = try await userAPIService.signup(
                request: SignupRequest(
                    gender: selectedGender.rawValue,
                    email: email,
                    password: password,
                    phoneNum: phoneNum,
                    nickname: nickname
                )
            )

            loginId = email
            loginPassword = ""
            signupEmail = ""
            signupPassword = ""
            signupNickname = ""
            signupPhoneNumber = ""
            authNoticeMessage = "회원가입이 완료되었습니다. 로그인해주세요."
            onboardingStep = .login
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            signupMessage = message

            if message.contains("이메일") {
                emailCheckMessage = message.contains("중복") || message.contains("가입된") ? "중복된 이메일입니다." : message
            }

            if message.contains("닉네임") {
                nicknameCheckMessage = message.contains("중복") ? "중복된 닉네임입니다." : message
            }
        }
    }

    // 작성한 일기를 저장하고 조건에 따라 교환 결과를 생성
    func saveDiary() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !content.isEmpty else { return }

        let newEntry = DiaryEntry(dateText: formattedToday(), title: title, content: content, mood: "기대")
        diaryEntries.insert(newEntry, at: 0)

        if exchangeStories.isEmpty || diaryEntries.count.isMultiple(of: 2) {
            let partnerEntry = DiaryEntry(
                dateText: formattedToday(),
                title: "오늘의 작은 위로",
                content: "낯선 하루였지만 제 마음을 잘 지켜낸 것 같아요.",
                mood: "담담"
            )
            let exchange = ExchangeStory(
                partnerName: "별빛님",
                daysRemaining: 3,
                myEntry: newEntry,
                partnerEntry: partnerEntry,
                isActive: true
            )
            exchangeStories.insert(exchange, at: 0)
            latestExchange = exchange
            selectedTab = .otherStories
        }

        draftTitle = ""
        draftContent = ""
    }

    // 교환 목록에서 연결을 종료
    func closeExchange(_ story: ExchangeStory) {
        exchangeStories.removeAll { $0.id == story.id }
    }

    // 오늘 날짜를 화면용 문자열로 변환
    private func formattedToday() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter.string(from: Date())
    }

    // 이메일 형식을 간단히 검사
    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}
