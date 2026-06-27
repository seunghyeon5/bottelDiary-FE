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

        let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
        let message = apiError?.message ?? "회원가입 요청에 실패했습니다."
        throw SignupServiceError.server(message: message, statusCode: httpResponse.statusCode)
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
