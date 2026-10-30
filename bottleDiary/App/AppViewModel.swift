import Foundation

// 앱 전체 화면 흐름과 목업 데이터를 관리하는 뷰모델
@MainActor
final class AppViewModel: ObservableObject {
    private let userAPIService = UserAPIService()
    private let authSessionStore = AuthSessionStore.shared

    @Published var currentUserId: Int?
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
    @Published var diarySaveMessage = ""
    @Published var loginMessage = ""
    @Published var diaryHistoryMessage = ""
    @Published var isSubmittingLogin = false
    @Published var isSubmittingSignup = false
    @Published var isSubmittingDiary = false
    @Published var selectedTab: BottleDiaryTab = .myStories
    @Published var diaryEntries: [DiaryEntry] = []
    @Published var exchangeStories: [ExchangeStory] = []
    @Published var draftTitle = ""
    @Published var draftContent = ""
    @Published var draftMood = "기대"
    @Published var latestExchange: ExchangeStory?
    @Published var authToken: String?
    @Published var currentUser: UserProfileResponse?
    @Published var diaryHistoryPage = 0
    @Published var hasMoreDiaryHistory = false
    @Published var diaryFromDate = ""
    @Published var diaryToDate = ""
    @Published var diaryMoodFilter = ""
    @Published var matchNotifications: [MatchNotification] = []
    @Published var accountMessage = ""
    @Published var recoverableDiaries: [DeletedDiaryRecovery] = [] {
        didSet { saveRecoverableDiaries() }
    }
    @Published var toastMessage = ""

    init() {
        recoverableDiaries = loadRecoverableDiaries()
        removeExpiredRecoveries()
    }

    // 로그인 입력이 완료되면 메인 화면으로 이동
    func login() async {
        let trimmedId = loginId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = loginPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        loginMessage = ""
        diaryHistoryMessage = ""
        authToken = nil
        authSessionStore.clear()
        guard isValidEmail(trimmedId) else {
            loginMessage = "올바른 이메일 형식이 아닙니다."
            return
        }

        guard !trimmedPassword.isEmpty else {
            loginMessage = "비밀번호를 입력해주세요."
            return
        }

        isSubmittingLogin = true
        defer { isSubmittingLogin = false }

        do {
            let user = try await userAPIService.login(
                request: LoginRequest(email: trimmedId, password: trimmedPassword)
            )
            applyLoggedInUser(user)
            onboardingStep = .completed

            do {
                try await loadDiaryHistory(reset: true)
                await loadMatchNotifications()
            } catch {
                if isSessionExpired(error) {
                    logout()
                    return
                }
                diaryEntries = []
                diaryHistoryMessage = "일기 목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요."
            }
        } catch {
            authToken = nil
            authSessionStore.clear()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            loginMessage = message
        }
    }

    // 회원가입을 누르면 온보딩 첫 단계로 이동
    func startSignup() {
        authNoticeMessage = ""
        signupMessage = ""
        onboardingStep = .gender
    }

    // 성별 선택 후 전화번호 입력 화면으로 이동
    func selectGender(_ gender: GenderOption) {
        selectedGender = gender
        onboardingStep = .signup
    }

    // 이메일 입력 형식과 서버 최종 확인 방식을 안내
    func checkEmailDuplicate() async {
        let trimmedEmail = signupEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        emailCheckMessage = ""

        guard !trimmedEmail.isEmpty else {
            emailCheckMessage = "이메일을 입력해주세요."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            emailCheckMessage = "올바른 이메일 형식이 아닙니다."
            return
        }

        do {
            let response = try await userAPIService.checkEmailDuplicate(email: trimmedEmail)
            if response.isDuplicate {
                emailCheckMessage = response.message ?? "중복된 이메일입니다."
            } else {
                emailCheckMessage = response.message ?? "사용 가능한 이메일입니다."
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            emailCheckMessage = message
        }
    }

    // 닉네임 입력 상태를 확인
    func checkNicknameDuplicate() async {
        let trimmedNickname = signupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        nicknameCheckMessage = ""

        guard !trimmedNickname.isEmpty else {
            nicknameCheckMessage = "닉네임을 입력해주세요."
            return
        }

        guard trimmedNickname.count >= 2 else {
            nicknameCheckMessage = "닉네임은 2자 이상 입력해주세요."
            return
        }

        do {
            let response = try await userAPIService.checkNicknameDuplicate(nickname: trimmedNickname)
            if response.isDuplicate {
                nicknameCheckMessage = response.message ?? "중복된 닉네임입니다."
            } else {
                nicknameCheckMessage = response.message ?? "사용 가능한 닉네임입니다."
            }
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            nicknameCheckMessage = message
        }
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
            loginPassword = password
            signupEmail = ""
            signupPassword = ""
            signupNickname = ""
            signupPhoneNumber = ""
            authNoticeMessage = ""

            await login()
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
    func saveDiary() async -> Bool {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let content = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        diarySaveMessage = ""

        guard !title.isEmpty, !content.isEmpty else {
            diarySaveMessage = "제목과 내용을 모두 입력해주세요."
            return false
        }

        isSubmittingDiary = true
        defer { isSubmittingDiary = false }

        let response: DiaryCreateResponse
        
        do {
            response = try await userAPIService.createDiary(
                request: DiaryCreateRequest(
                    diaryDate: todayServerDate(),
                    title: title,
                    content: content,
                    mood: draftMood
                )
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if message.contains("중복") || message.contains("이미") || message.contains("날짜") {
                diarySaveMessage = "오늘 날짜의 일기가 이미 있습니다. 기존 일기를 수정하거나 삭제 후 다시 작성해주세요."
            } else {
                diarySaveMessage = message
            }
            if isSessionExpired(error) { logout() }
            return false
        }

        let diaryPayload = response.diary
        let newEntry = DiaryEntry(
            serverId: diaryPayload?.id,
            dateText: formattedToday(from: diaryPayload?.diaryDate),
            title: diaryPayload?.title ?? title,
            content: diaryPayload?.content ?? content,
            mood: diaryPayload?.mood ?? draftMood
        )
        diaryEntries.insert(newEntry, at: 0)

        if let exchangePayload = response.exchange,
           let myDiary = exchangePayload.myDiary,
           let partnerDiary = exchangePayload.partnerDiary {
            let exchange = ExchangeStory(
                partnerName: "별빛님",
                daysRemaining: 3,
                myEntry: DiaryEntry(
                    serverId: myDiary.id,
                    dateText: formattedToday(from: myDiary.diaryDate),
                    title: myDiary.title ?? newEntry.title,
                    content: myDiary.content ?? newEntry.content,
                    mood: myDiary.mood ?? newEntry.mood
                ),
                partnerEntry: DiaryEntry(
                    serverId: partnerDiary.id,
                    dateText: formattedToday(from: partnerDiary.diaryDate),
                    title: partnerDiary.title ?? "상대의 하루",
                    content: partnerDiary.content ?? "아직 교환된 상대 일기 내용이 없습니다.",
                    mood: partnerDiary.mood ?? "담담"
                ),
                isActive: exchangePayload.active ?? (exchangePayload.status == "ACTIVE"),
                status: exchangePayload.status
            )
            exchangeStories.insert(exchange, at: 0)
            latestExchange = exchange
            selectedTab = .otherStories
        }

        draftTitle = ""
        draftContent = ""
        draftMood = "기대"
        diarySaveMessage = ""
        showToast("오늘의 일기를 저장했습니다.")
        return true
    }

    // 로그인 완료 후 사용자 정보를 화면 상태에 반영
    private func applyLoggedInUser(_ user: UserResponsePayload) {
        currentUserId = user.id
        currentUser = user
        authToken = authSessionStore.authorizationHeaderValue
        authNoticeMessage = ""
        signupMessage = ""
        loginMessage = ""
        diaryHistoryMessage = ""
    }

    // 현재 로그인한 사용자의 일기 히스토리를 불러옴
    func loadDiaryHistory(
        reset: Bool = true,
        fromDate: String? = nil,
        toDate: String? = nil,
        mood: String? = nil
    ) async throws {
        let page = reset ? 0 : diaryHistoryPage + 1
        let history = try await userAPIService.fetchDiaryHistory(
            page: page,
            size: 10,
            fromDate: fromDate ?? diaryFromDate,
            toDate: toDate ?? diaryToDate,
            mood: mood ?? diaryMoodFilter
        )
        let entries = history.content.map { payload in
            DiaryEntry(
                serverId: payload.id,
                dateText: formattedToday(from: payload.diaryDate),
                title: payload.title ?? "제목 없음",
                content: payload.content ?? "",
                mood: payload.mood ?? "기록"
            )
        }
        if reset { diaryEntries = entries } else { diaryEntries.append(contentsOf: entries) }
        diaryHistoryPage = page
        hasMoreDiaryHistory = history.last ?? ((history.number ?? page) + 1 < (history.totalPages ?? page + 1))
        diaryHistoryMessage = ""
    }

    // 날짜와 기분 조건으로 일기 히스토리를 다시 조회
    func applyDiaryFilters(fromDate: String, toDate: String, mood: String) async {
        diaryFromDate = fromDate
        diaryToDate = toDate
        diaryMoodFilter = mood
        do {
            try await loadDiaryHistory(reset: true)
        } catch {
            diaryEntries = []
            diaryHistoryMessage = "필터 조건에 맞는 일기를 불러오지 못했습니다."
            if isSessionExpired(error) { logout() }
        }
    }

    // 특정 일기의 최신 상세 정보를 서버에서 다시 불러옴
    func loadDiaryDetail(_ diary: DiaryEntry) async -> DiaryEntry? {
        guard let serverId = diary.serverId else { return nil }
        do {
            let payload = try await userAPIService.fetchDiaryDetail(diaryId: serverId)
            return diaryEntry(from: payload, fallback: diary)
        } catch {
            if isSessionExpired(error) { logout() }
            return nil
        }
    }

    // 선택한 일기를 수정하고 목록의 해당 항목도 즉시 갱신
    func updateDiary(_ diary: DiaryEntry, title: String, content: String) async -> DiaryEntry? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty, !trimmedContent.isEmpty else {
            diarySaveMessage = "제목과 내용을 모두 입력해주세요."
            return nil
        }

        guard let serverId = diary.serverId else {
            diarySaveMessage = "서버 일기 ID가 없어 수정할 수 없습니다."
            return nil
        }

        do {
            let response = try await userAPIService.updateDiary(
                diaryId: serverId,
                request: DiaryUpdateRequest(title: trimmedTitle, content: trimmedContent, mood: diary.mood)
            )
            let updatedDiary = DiaryEntry(
                serverId: response?.id ?? diary.serverId,
                dateText: response?.diaryDate.map { formattedToday(from: $0) } ?? diary.dateText,
                title: response?.title ?? trimmedTitle,
                content: response?.content ?? trimmedContent,
                mood: response?.mood ?? diary.mood
            )
            replaceDiary(updatedDiary, matching: diary)
            diarySaveMessage = ""
            showToast("일기를 수정했습니다.")
            return updatedDiary
        } catch {
            diarySaveMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if isSessionExpired(error) { logout() }
            return nil
        }
    }

    // 선택한 일기를 삭제하고 목록에서 제거
    func deleteDiary(_ diary: DiaryEntry) async -> Bool {
        guard let serverId = diary.serverId else {
            diarySaveMessage = "서버 일기 ID가 없어 삭제할 수 없습니다."
            return false
        }

        do {
            try await userAPIService.deleteDiary(diaryId: serverId)
            recoverableDiaries.insert(DeletedDiaryRecovery(diary: diary), at: 0)
            do {
                try await loadDiaryHistory(reset: true)
            } catch {
                diaryHistoryMessage = "일기 목록을 다시 불러오지 못했습니다. 잠시 후 재시도해주세요."
            }
            diarySaveMessage = ""
            showToast("삭제한 일기는 복구 목록에 저장되며 24시간 동안 보관됩니다.")
            return true
        } catch {
            diarySaveMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if isSessionExpired(error) { logout() }
            return false
        }
    }

    // 선택한 삭제 일기를 복구하고 서버 목록을 다시 조회
    func restoreDiary(_ recovery: DeletedDiaryRecovery) async -> Bool {
        removeExpiredRecoveries()
        guard !recovery.isExpired else {
            showToast("복구 가능 기간이 만료되었습니다.")
            return false
        }
        do {
            _ = try await userAPIService.restoreDiary(diaryId: recovery.serverId)
            recoverableDiaries.removeAll { $0.id == recovery.id }
            do {
                try await loadDiaryHistory(reset: true)
            } catch {
                diaryHistoryMessage = "복구는 완료되었지만 목록을 다시 불러오지 못했습니다."
            }
            diarySaveMessage = ""
            showToast("일기를 복구했습니다.")
            return true
        } catch {
            diarySaveMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if isSessionExpired(error) { logout() }
            return false
        }
    }

    // 마이페이지 정보를 서버에서 조회
    func loadCurrentUser() async {
        do {
            currentUser = try await userAPIService.fetchCurrentUser()
            currentUserId = currentUser?.id ?? currentUserId
            accountMessage = ""
        } catch {
            accountMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if isSessionExpired(error) { logout() }
        }
    }

    // 로그인 사용자의 계정을 탈퇴하고 인증 상태를 초기화
    func withdraw() async -> Bool {
        do {
            try await userAPIService.withdrawCurrentUser()
            logout()
            return true
        } catch {
            accountMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            if isSessionExpired(error) { logout() }
            return false
        }
    }

    // 새 교환 알림을 불러옴
    func loadMatchNotifications() async {
        do {
            matchNotifications = try await userAPIService.fetchMatchNotifications()
        } catch {
            if isSessionExpired(error) { logout() }
        }
    }

    // 선택한 교환 알림을 읽음 처리
    func markNotificationRead(_ notification: MatchNotification) async {
        guard let index = matchNotifications.firstIndex(where: { $0.id == notification.id }) else { return }
        do {
            try await userAPIService.markMatchNotificationRead(notificationId: notification.id)
        } catch {
            if isSessionExpired(error) { logout() }
            return
        }
        let updated = MatchNotification(
            id: notification.id,
            matchId: notification.matchId,
            message: notification.message,
            createdAt: notification.createdAt,
            read: true
        )
        matchNotifications[index] = updated
    }

    // 앱의 로그인 상태와 사용자별 데이터를 초기화
    func logout() {
        authSessionStore.clear()
        authToken = nil
        currentUserId = nil
        currentUser = nil
        diaryEntries = []
        exchangeStories = []
        matchNotifications = []
        latestExchange = nil
        recoverableDiaries = []
        toastMessage = ""
        onboardingStep = .login
    }

    // 네트워크 작업 결과를 잠시 보여주는 공통 안내 메시지
    func showToast(_ message: String) {
        toastMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if toastMessage == message { toastMessage = "" }
        }
    }

    // 인증 만료 오류인지 확인
    private func isSessionExpired(_ error: Error) -> Bool {
        if case SignupServiceError.sessionExpired = error { return true }
        return false
    }

    private func diaryEntry(from payload: DiaryResponsePayload, fallback: DiaryEntry) -> DiaryEntry {
        DiaryEntry(
            serverId: payload.id ?? fallback.serverId,
            dateText: payload.diaryDate.map { formattedToday(from: $0) } ?? fallback.dateText,
            title: payload.title ?? fallback.title,
            content: payload.content ?? fallback.content,
            mood: payload.mood ?? fallback.mood
        )
    }

    // 만료된 복구 항목을 제거
    func removeExpiredRecoveries() {
        recoverableDiaries.removeAll { $0.isExpired }
    }

    // 복구 가능한 일기를 앱 재실행 후에도 유지
    private func saveRecoverableDiaries() {
        guard let data = try? JSONEncoder().encode(recoverableDiaries) else { return }
        UserDefaults.standard.set(data, forKey: "bottleDiary.recoverableDiaries")
    }

    private func loadRecoverableDiaries() -> [DeletedDiaryRecovery] {
        guard let data = UserDefaults.standard.data(forKey: "bottleDiary.recoverableDiaries"),
              let recoveries = try? JSONDecoder().decode([DeletedDiaryRecovery].self, from: data) else {
            return []
        }
        return recoveries
    }

    private func replaceDiary(_ updatedDiary: DiaryEntry, matching diary: DiaryEntry) {
        guard let index = diaryEntries.firstIndex(where: { $0.id == diary.id }) else { return }
        diaryEntries[index] = updatedDiary
    }

    // 교환 목록에서 연결을 종료
    func closeExchange(_ story: ExchangeStory) {
        exchangeStories.removeAll { $0.id == story.id }
    }

    // 오늘 날짜를 화면용 문자열로 변환
    private func formattedToday(from serverDate: String? = nil) -> String {
        if let serverDate,
           let date = serverDateFormatter.date(from: serverDate) {
            return displayDateFormatter.string(from: date)
        }

        return displayDateFormatter.string(from: Date())
    }

    // 서버 전송용 오늘 날짜 문자열
    private func todayServerDate() -> String {
        serverDateFormatter.string(from: Date())
    }

    private var displayDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M.d E"
        return formatter
    }

    private var serverDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    // 이메일 형식을 간단히 검사
    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}
