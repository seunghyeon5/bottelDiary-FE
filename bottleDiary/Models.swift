import Foundation

// 온보딩 진행 단계를 관리하는 상태값
enum OnboardingStep {
    case login
    case gender
    case phone
    case completed
}

// 메인 화면 상단 탭 종류
enum BottleDiaryTab: String, CaseIterable {
    case myStories = "내 이야기"
    case otherStories = "다른 이야기"
}

// 성별 선택 화면에서 사용하는 옵션
enum GenderOption: String, CaseIterable, Identifiable {
    case male = "남성"
    case female = "여성"

    var id: String { rawValue }
}

// 사용자가 작성한 일기 한 건을 나타내는 모델
struct DiaryEntry: Identifiable {
    let id = UUID()
    let dateText: String
    let title: String
    let content: String
    let mood: String
}

// 나와 상대방의 일기 교환 정보를 담는 모델
struct ExchangeStory: Identifiable {
    let id = UUID()
    let partnerName: String
    let daysRemaining: Int
    let myEntry: DiaryEntry
    let partnerEntry: DiaryEntry
    let isActive: Bool
}
