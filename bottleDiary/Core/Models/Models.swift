import Foundation

// 온보딩 진행 단계를 관리하는 상태값
enum OnboardingStep {
    case login
    case gender
    case signup
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
    let serverId: Int?
    let dateText: String
    let title: String
    let content: String
    let mood: String

    init(serverId: Int? = nil, dateText: String, title: String, content: String, mood: String) {
        self.serverId = serverId
        self.dateText = dateText
        self.title = title
        self.content = content
        self.mood = mood
    }
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

// 회원가입 요청에 사용하는 API 모델
struct SignupRequest: Codable {
    let gender: String
    let email: String
    let password: String
    let phoneNum: String
    let nickname: String
}

// 회원가입 응답을 받기 위한 API 모델
struct SignupResponse: Codable {
    let id: Int?
    let email: String?
    let nickname: String?
    let gender: String?
    let phoneNum: String?
}

// 이메일/닉네임 중복 확인에 사용하는 API 응답 모델
struct UserDuplicateCheckResponse: Codable {
    let duplicate: Bool?
    let exists: Bool?
    let exist: Bool?
    let isDuplicateValue: Bool?
    let available: Bool?
    let message: String?

    var isDuplicate: Bool {
        if let duplicate { return duplicate }
        if let exists { return exists }
        if let exist { return exist }
        if let isDuplicateValue { return isDuplicateValue }
        if let available { return !available }
        return false
    }

    private enum CodingKeys: String, CodingKey {
        case duplicate
        case exists
        case exist
        case isDuplicateValue = "isDuplicate"
        case available
        case message
    }
}

// 로그인 요청/응답에 사용하는 API 모델
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct UserResponsePayload: Codable {
    let tokenType: String?
    let token: String?
    let id: Int?
    let email: String?
    let nickname: String?
    let gender: String?
    let phoneNum: String?
}

// 일기 생성 요청/응답에 사용하는 API 모델
struct DiaryCreateRequest: Codable {
    let diaryDate: String
    let title: String
    let content: String
    let mood: String?
}

// 일기 수정 요청에 사용하는 API 모델
struct DiaryUpdateRequest: Codable {
    let title: String
    let content: String
    let mood: String?
}

struct DiaryCreateResponse: Codable {
    let diary: DiaryResponsePayload?
    let exchange: DiaryExchangeResponsePayload?
    let message: String?
}

struct DiaryResponsePayload: Codable {
    let id: Int?
    let userId: Int?
    let diaryDate: String?
    let title: String?
    let content: String?
    let mood: String?
    let createdAt: String?
}

struct DiaryExchangeResponsePayload: Codable {
    let exchangeId: Int?
    let exchangeDate: String?
    let myDiary: DiaryResponsePayload?
    let partnerDiary: DiaryResponsePayload?
    let active: Bool?
}

// 서버 에러 메시지를 받기 위한 공통 API 모델
struct APIErrorResponse: Codable {
    let status: Int?
    let error: String?
    let message: String?
    let path: String?
}
