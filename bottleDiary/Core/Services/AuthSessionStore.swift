import Foundation

// 로그인 후 전달받은 JWT 토큰을 앱에서 공용으로 보관하는 세션 저장소
final class AuthSessionStore {
    static let shared = AuthSessionStore()

    private init() {}

    private(set) var authorizationHeaderValue: String?

    // 로그인 응답 본문 또는 헤더 값을 기반으로 Authorization 헤더 문자열을 저장
    func updateToken(token: String?, tokenType: String?, authorizationHeader: String?) {
        if let authorizationHeader,
           !authorizationHeader.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            authorizationHeaderValue = authorizationHeader
            return
        }

        guard let token,
              !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authorizationHeaderValue = nil
            return
        }

        let normalizedTokenType = tokenType?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedType = (normalizedTokenType?.isEmpty == false) ? normalizedTokenType! : "Bearer"

        authorizationHeaderValue = "\(normalizedType) \(token)"
    }

    // 로그아웃 또는 세션 초기화 시 저장된 토큰을 제거
    func clear() {
        authorizationHeaderValue = nil
    }
}
