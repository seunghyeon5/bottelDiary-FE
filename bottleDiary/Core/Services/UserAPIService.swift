import Foundation

// 회원가입 API 통신을 담당하는 서비스
struct UserAPIService {
    // xcconfig에서 Info.plist로 주입된 서버 주소를 읽어 API 기본 주소로 사용
    private let baseURL = URL(string: Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? "")!
    private let authSessionStore = AuthSessionStore.shared

    // 이메일 중복확인 요청을 서버로 전송
    func checkEmailDuplicate(email: String) async throws -> UserDuplicateCheckResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/users/exist-email"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(UserDuplicateCheckResponse.self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "이메일 중복 확인에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 닉네임 중복확인 요청을 서버로 전송
    func checkNicknameDuplicate(nickname: String) async throws -> UserDuplicateCheckResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/users/exist-nickname"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "nickname", value: nickname)]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(UserDuplicateCheckResponse.self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "닉네임 중복 확인에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 회원가입 요청을 서버로 전송
    func signup(request: SignupRequest) async throws -> SignupResponse {
        let url = baseURL.appendingPathComponent("api/users/signup")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(SignupResponse.self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "회원가입 요청에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 로그인 요청을 서버로 전송
    func login(request: LoginRequest) async throws -> UserResponsePayload {
        let url = baseURL.appendingPathComponent("api/users/login")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            let user = try JSONDecoder().decode(UserResponsePayload.self, from: data)
            let authorizationHeader = httpResponse.value(forHTTPHeaderField: "Authorization")
            authSessionStore.updateToken(
                token: user.token,
                tokenType: user.tokenType,
                authorizationHeader: authorizationHeader
            )
            return user
        }

        let message = decodeErrorMessage(from: data, fallback: "로그인 요청에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 로그인한 사용자의 마이페이지 정보를 서버에서 조회
    func fetchCurrentUser() async throws -> UserProfileResponse {
        let url = baseURL.appendingPathComponent("api/users/me")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "사용자 정보를 불러오지 못했습니다.")
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }

    // 로그인한 사용자의 계정을 탈퇴 처리
    func withdrawCurrentUser() async throws {
        let url = baseURL.appendingPathComponent("api/users/me/withdraw")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "POST"))
        try validate(response: response, data: data, fallback: "회원 탈퇴에 실패했습니다.")
    }

    // 일기 생성 요청을 서버로 전송
    func createDiary(request: DiaryCreateRequest) async throws -> DiaryCreateResponse {
        let url = baseURL.appendingPathComponent("api/diaries")
        var urlRequest = authorizedRequest(url: url, method: "POST")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(DiaryCreateResponse.self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "일기 생성 요청에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 사용자의 일기 히스토리를 서버에서 조회
    func fetchDiaryHistory(
        page: Int = 0,
        size: Int = 10,
        fromDate: String? = nil,
        toDate: String? = nil,
        mood: String? = nil
    ) async throws -> DiaryHistoryPageResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/diaries/history"), resolvingAgainstBaseURL: false)
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        if let fromDate, !fromDate.isEmpty { queryItems.append(URLQueryItem(name: "fromDate", value: fromDate)) }
        if let toDate, !toDate.isEmpty { queryItems.append(URLQueryItem(name: "toDate", value: toDate)) }
        if let mood, !mood.isEmpty { queryItems.append(URLQueryItem(name: "mood", value: mood)) }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw URLError(.badURL) }
        let urlRequest = authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data, fallback: "일기 히스토리 조회에 실패했습니다.")
        if let pageResponse = try? JSONDecoder().decode(DiaryHistoryPageResponse.self, from: data) {
            return pageResponse
        }
        let legacyContent = try JSONDecoder().decode([DiaryResponsePayload].self, from: data)
        return DiaryHistoryPageResponse(content: legacyContent, totalPages: 1, totalElements: legacyContent.count, number: 0, size: legacyContent.count, first: true, last: true)
    }

    // 선택한 일기 상세 정보를 서버에서 조회
    func fetchDiaryDetail(diaryId: Int) async throws -> DiaryResponsePayload {
        let url = baseURL.appendingPathComponent("api/diaries/\(diaryId)")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "일기 상세 정보를 불러오지 못했습니다.")
        return try JSONDecoder().decode(DiaryResponsePayload.self, from: data)
    }

    // 기존 일기의 제목과 내용을 서버에서 수정
    func updateDiary(diaryId: Int, request: DiaryUpdateRequest) async throws -> DiaryResponsePayload? {
        let url = baseURL.appendingPathComponent("api/diaries/\(diaryId)")
        var urlRequest = authorizedRequest(url: url, method: "PUT")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            guard !data.isEmpty else { return nil }
            if let payload = try? JSONDecoder().decode(DiaryResponsePayload.self, from: data) {
                return payload
            }
            return try JSONDecoder().decode(DiaryCreateResponse.self, from: data).diary
        }

        let message = decodeErrorMessage(from: data, fallback: "일기 수정 요청에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 기존 일기를 서버에서 삭제
    func deleteDiary(diaryId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/diaries/\(diaryId)")
        let urlRequest = authorizedRequest(url: url, method: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = decodeErrorMessage(from: data, fallback: "일기 삭제 요청에 실패했습니다.")
            throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
        }
    }

    // 삭제된 일기를 다시 활성화
    func restoreDiary(diaryId: Int) async throws -> DiaryResponsePayload? {
        let url = baseURL.appendingPathComponent("api/diaries/\(diaryId)/restore")
        let urlRequest = authorizedRequest(url: url, method: "PATCH")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data, fallback: "일기 복구에 실패했습니다.")
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode(DiaryResponsePayload.self, from: data)
    }

    // 로그인 사용자의 교환 알림 목록을 조회
    func fetchMatchNotifications() async throws -> [MatchNotification] {
        let url = baseURL.appendingPathComponent("api/matches/notifications")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "교환 알림을 불러오지 못했습니다.")
        return try JSONDecoder().decode([MatchNotification].self, from: data)
    }

    // 교환 알림을 읽음 상태로 변경
    func markMatchNotificationRead(notificationId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/matches/notifications/\(notificationId)/read")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "PATCH"))
        try validate(response: response, data: data, fallback: "알림 읽음 처리에 실패했습니다.")
    }

    // 나에게 도착해 답장을 기다리는 일기 목록을 조회
    func fetchMatchInbox() async throws -> [DiaryExchangeResponsePayload] {
        let url = baseURL.appendingPathComponent("api/matches/inbox")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "수신 대기 일기를 불러오지 못했습니다.")
        return try JSONDecoder().decode([DiaryExchangeResponsePayload].self, from: data)
    }

    // 받은 일기에 답장 일기를 작성해 교환을 완료
    func replyToMatch(exchangeId: Int, request: DiaryCreateRequest) async throws -> DiaryExchangeResponsePayload {
        let url = baseURL.appendingPathComponent("api/matches/\(exchangeId)/reply")
        var urlRequest = authorizedRequest(url: url, method: "POST")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data, fallback: "답장 전송에 실패했습니다.")
        return try JSONDecoder().decode(DiaryExchangeResponsePayload.self, from: data)
    }

    // 받은 일기 교환 요청을 거절
    func rejectMatch(exchangeId: Int) async throws -> DiaryExchangeResponsePayload {
        let url = baseURL.appendingPathComponent("api/matches/\(exchangeId)/reject")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "POST"))
        try validate(response: response, data: data, fallback: "교환 요청 거절에 실패했습니다.")
        return try JSONDecoder().decode(DiaryExchangeResponsePayload.self, from: data)
    }

    // 답장이 오지 않았거나 상대가 없었던 일기를 다시 매칭
    func matchDiary(diaryId: Int) async throws -> DiaryExchangeResponsePayload? {
        let url = baseURL.appendingPathComponent("api/matches")
        var urlRequest = authorizedRequest(url: url, method: "POST")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(MatchCreateRequest(diaryId: diaryId))
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        try validate(response: response, data: data, fallback: "재매칭 요청에 실패했습니다.")
        guard !data.isEmpty else { return nil }
        return try JSONDecoder().decode(DiaryExchangeResponsePayload.self, from: data)
    }

    // 내가 보내거나 받은 교환 요청의 상태를 조회
    func fetchMatchConnections() async throws -> [DiaryExchangeResponsePayload] {
        let url = baseURL.appendingPathComponent("api/matches")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "교환 목록을 불러오지 못했습니다.")
        return try JSONDecoder().decode([DiaryExchangeResponsePayload].self, from: data)
    }

    // 교환 연결을 종료
    func disconnectMatch(exchangeId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/matches/\(exchangeId)")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "DELETE"))
        try validate(response: response, data: data, fallback: "교환 종료에 실패했습니다.")
    }

    // 상대를 차단
    func blockUser(userId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/matches/blocks/\(userId)")
        let (data, response) = try await URLSession.shared.data(for: urlRequest(url: url, method: "POST"))
        try validate(response: response, data: data, fallback: "상대 차단에 실패했습니다.")
    }

    // 차단한 상대를 다시 허용
    func unblockUser(userId: Int) async throws {
        let url = baseURL.appendingPathComponent("api/matches/blocks/\(userId)")
        let (data, response) = try await URLSession.shared.data(for: urlRequest(url: url, method: "DELETE"))
        try validate(response: response, data: data, fallback: "차단 해제에 실패했습니다.")
    }

    // 로그인 사용자가 차단한 사용자 목록을 조회
    func fetchBlockedUsers() async throws -> [BlockedUserResponse] {
        let url = baseURL.appendingPathComponent("api/matches/blocks")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest(url: url, method: "GET"))
        try validate(response: response, data: data, fallback: "차단 목록을 불러오지 못했습니다.")
        return try JSONDecoder().decode([BlockedUserResponse].self, from: data)
    }

    private func urlRequest(url: URL, method: String) -> URLRequest {
        authorizedRequest(url: url, method: method)
    }

    // 인증 API 응답의 성공 여부를 공통으로 확인
    private func validate(response: URLResponse, data: Data, fallback: String) throws {
        guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if httpResponse.statusCode == 401 {
            authSessionStore.clear()
            throw SignupServiceError.sessionExpired
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SignupServiceError.server(message: decodeErrorMessage(from: data, fallback: fallback), statusCode: httpResponse.statusCode)
        }
    }

    private func decodeErrorMessage(from data: Data, fallback: String) -> String {
        let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        return apiError?.message ?? fallback
    }

    // 토큰이 있으면 Authorization 헤더를 함께 붙이는 공통 요청 생성기
    private func authorizedRequest(url: URL, method: String) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method

        if let authorizationHeaderValue = authSessionStore.authorizationHeaderValue {
            urlRequest.setValue(authorizationHeaderValue, forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }
}

// 회원가입 API 처리 중 사용하는 에러 타입
enum SignupServiceError: LocalizedError {
    case server(message: String, statusCode: Int)
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case let .server(message, _):
            return message
        case .sessionExpired:
            return "로그인 세션이 만료되었습니다. 다시 로그인해주세요."
        }
    }
}
