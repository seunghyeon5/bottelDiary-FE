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
    func fetchDiaryHistory(userId: Int) async throws -> [DiaryResponsePayload] {
        let url = baseURL.appendingPathComponent("api/diaries/users/\(userId)/history")
        let urlRequest = authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode([DiaryResponsePayload].self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "일기 히스토리 조회에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 기존 일기의 제목과 내용을 서버에서 수정
    func updateDiary(diaryId: Int, userId: Int, request: DiaryUpdateRequest) async throws -> DiaryResponsePayload? {
        let url = diaryActionURL(diaryId: diaryId, userId: userId)
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
    func deleteDiary(diaryId: Int, userId: Int) async throws {
        let url = diaryActionURL(diaryId: diaryId, userId: userId)
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

    // 일기 수정/삭제 API가 요구하는 userId 쿼리 파라미터를 공통으로 생성
    private func diaryActionURL(diaryId: Int, userId: Int) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/diaries/\(diaryId)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "userId", value: String(userId))]
        return components?.url ?? baseURL.appendingPathComponent("api/diaries/\(diaryId)")
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

    var errorDescription: String? {
        switch self {
        case let .server(message, _):
            return message
        }
    }
}
