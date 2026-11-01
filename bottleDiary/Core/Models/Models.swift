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

// 삭제 후 24시간 동안 복구할 수 있는 일기 정보를 담는 모델
struct DeletedDiaryRecovery: Identifiable, Codable {
    let id: UUID
    let serverId: Int
    let dateText: String
    let title: String
    let content: String
    let mood: String
    let deletedAt: Date

    init(diary: DiaryEntry, deletedAt: Date = Date()) {
        self.id = UUID()
        self.serverId = diary.serverId ?? 0
        self.dateText = diary.dateText
        self.title = diary.title
        self.content = diary.content
        self.mood = diary.mood
        self.deletedAt = deletedAt
    }

    var diary: DiaryEntry {
        DiaryEntry(serverId: serverId, dateText: dateText, title: title, content: content, mood: mood)
    }

    var expiresAt: Date {
        deletedAt.addingTimeInterval(24 * 60 * 60)
    }

    var isExpired: Bool {
        Date() >= expiresAt
    }
}

// 나와 상대방의 일기 교환 정보를 담는 모델
struct ExchangeStory: Identifiable {
    let id = UUID()
    let exchangeId: Int?
    let partnerUserId: Int?
    let partnerName: String
    let daysRemaining: Int
    let myEntry: DiaryEntry
    let partnerEntry: DiaryEntry
    let isActive: Bool
    let status: String?

    init(exchangeId: Int? = nil, partnerUserId: Int? = nil, partnerName: String, daysRemaining: Int, myEntry: DiaryEntry, partnerEntry: DiaryEntry, isActive: Bool, status: String? = nil) {
        self.exchangeId = exchangeId
        self.partnerUserId = partnerUserId
        self.partnerName = partnerName
        self.daysRemaining = daysRemaining
        self.myEntry = myEntry
        self.partnerEntry = partnerEntry
        self.isActive = isActive
        self.status = status
    }
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

// 로그인 사용자의 마이페이지 정보를 담는 API 모델
typealias UserProfileResponse = UserResponsePayload

// 일기 생성 요청/응답에 사용하는 API 모델
struct DiaryCreateRequest: Codable {
    let diaryDate: String
    let title: String
    let content: String
    let mood: String?
}

// 이미 작성한 일기를 다시 매칭할 때 사용하는 API 모델
struct MatchCreateRequest: Codable {
    let diaryId: Int
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
    let updatedAt: String?
}

// 일기 히스토리 페이징 응답을 담는 API 모델
struct DiaryHistoryPageResponse: Codable {
    let content: [DiaryResponsePayload]
    let totalPages: Int?
    let totalElements: Int?
    let number: Int?
    let size: Int?
    let first: Bool?
    let last: Bool?
}

struct DiaryExchangeResponsePayload: Codable, Identifiable {
    let exchangeId: Int?
    let exchangeDate: String?
    let senderUserId: Int?
    let recipientUserId: Int?
    let expiresAt: String?
    let myDiary: DiaryResponsePayload?
    let partnerDiary: DiaryResponsePayload?
    let active: Bool?
    let status: String?

    var id: Int { exchangeId ?? diaryIdFallback }

    private var diaryIdFallback: Int {
        myDiary?.id ?? partnerDiary?.id ?? 0
    }
}

// 새 교환 알림 정보를 담는 API 모델
struct MatchNotification: Decodable, Identifiable {
    let id: Int
    let matchId: Int?
    let message: String?
    let createdAt: String?
    let read: Bool

    init(id: Int, matchId: Int?, message: String?, createdAt: String?, read: Bool) {
        self.id = id
        self.matchId = matchId
        self.message = message
        self.createdAt = createdAt
        self.read = read
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case matchId
        case message
        case createdAt
        case read
        case isRead
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        matchId = try container.decodeIfPresent(Int.self, forKey: .matchId)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        read = try container.decodeIfPresent(Bool.self, forKey: .read)
            ?? container.decodeIfPresent(Bool.self, forKey: .isRead)
            ?? false
    }
}

// 서버 에러 메시지를 받기 위한 공통 API 모델
struct APIErrorResponse: Codable {
    let status: Int?
    let error: String?
    let message: String?
    let path: String?
}
