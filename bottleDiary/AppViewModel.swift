import Foundation

// 앱 전체 화면 흐름과 목업 데이터를 관리하는 뷰모델
final class AppViewModel: ObservableObject {
    @Published var onboardingStep: OnboardingStep = .gender
    @Published var selectedGender: GenderOption?
    @Published var phoneNumber = ""
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

    // 성별 선택 후 전화번호 입력 화면으로 이동
    func selectGender(_ gender: GenderOption) {
        selectedGender = gender
        onboardingStep = .phone
    }

    // 전화번호 입력이 끝나면 메인 화면으로 이동
    func completePhoneVerification() {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onboardingStep = .completed
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
}
