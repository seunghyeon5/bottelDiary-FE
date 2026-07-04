import Foundation

// 회원가입 API 통신을 담당하는 서비스
struct UserAPIService {
    private let baseURL = URL(string: "http://localhost:8080")!

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
            return try JSONDecoder().decode(UserResponsePayload.self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "로그인 요청에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    // 일기 생성 요청을 서버로 전송
    func createDiary(request: DiaryCreateRequest) async throws -> DiaryCreateResponse {
        let url = baseURL.appendingPathComponent("api/diaries")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
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
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode([DiaryResponsePayload].self, from: data)
        }

        let message = decodeErrorMessage(from: data, fallback: "일기 히스토리 조회에 실패했습니다.")
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
    }

    private func decodeErrorMessage(from data: Data, fallback: String) -> String {
        let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        return apiError?.message ?? fallback
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
