import SwiftUI

// 공통 온보딩 배경과 레이아웃을 제공하는 래퍼 화면
struct OnboardingScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#03060B"), Color(hex: "#294A75")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            StarFieldView()
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: proxy.size.height < 700 ? 18 : 26) {
                        Spacer(minLength: 0)
                            .frame(height: proxy.size.height < 700 ? 20 : 36)

                        MoonDecorationView()
                            .scaleEffect(proxy.size.height < 700 ? 0.9 : 1)

                        Text(title)
                            .font(.system(size: proxy.size.height < 700 ? 24 : 28, weight: .bold))
                            .minimumScaleFactor(0.85)
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: proxy.size.height < 700 ? 15 : 16, weight: .medium))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                            .minimumScaleFactor(0.9)

                        Spacer(minLength: 0)
                            .frame(height: proxy.size.height < 700 ? 20 : 46)

                        content

                        Spacer(minLength: proxy.size.height < 700 ? 24 : 40)
                    }
                    .frame(minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
                    .padding(.horizontal, 26)
                    .padding(.top, proxy.safeAreaInsets.top + 12)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 24)
                }
            }
        }
    }
}

// 로그인 화면에서 사용하는 입력 필드 컴포넌트
struct LoginInputField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            Group {
                if isSecure {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .foregroundStyle(.white)

            Rectangle()
                .fill(.white)
                .frame(height: 1)
        }
    }
}

// 회원가입 화면에서 버튼이 함께 있는 입력 필드 컴포넌트
struct SignupInputWithAction: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let buttonTitle: String
    var keyboardType: UIKeyboardType = .default
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 12) {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .sentences)
                    .autocorrectionDisabled(keyboardType == .emailAddress)
                    .foregroundStyle(.white)

                Button(buttonTitle) {
                    action()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "#BCE3F1"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }

            Rectangle()
                .fill(.white)
                .frame(height: 1)
        }
    }
}

// 내 이야기 탭에서 사용하는 일기 카드 컴포넌트
struct DiaryCardView: View {
    let diary: DiaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(diary.dateText)
                    .font(.headline)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            Text(diary.title)
                .font(.subheadline.weight(.semibold))
            Text(diary.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// 다른 이야기 탭에서 사용하는 교환 카드 컴포넌트
struct ExchangeCardView: View {
    let story: ExchangeStory
    let disconnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(story.partnerName)와 \(story.daysRemaining)일째")
                    .font(.headline)
                Spacer()
                Button("종료") {
                    disconnect()
                }
                .font(.caption.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("내 이야기")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(story.myEntry.title)
                    .font(.subheadline.weight(.semibold))
                Text(story.myEntry.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("다른 이야기")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(story.partnerEntry.title)
                    .font(.subheadline.weight(.semibold))
                Text(story.partnerEntry.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// 온보딩 상단에 들어가는 달 장식 컴포넌트
struct MoonDecorationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#B6AD6F"))
                .frame(width: 92, height: 92)
                .overlay(alignment: .topLeading) {
                    Circle().fill(Color(hex: "#9D9458")).frame(width: 12, height: 12).offset(x: 22, y: 22)
                }
                .overlay(alignment: .topTrailing) {
                    Circle().fill(Color(hex: "#9D9458")).frame(width: 9, height: 9).offset(x: -28, y: 32)
                }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.gray.opacity(0.55))
                .frame(width: 82, height: 24)
                .offset(x: -26, y: 32)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.gray.opacity(0.7))
                .frame(width: 76, height: 28)
                .offset(x: 16, y: 44)
        }
    }
}

// 배경의 별 장식을 그리는 컴포넌트
struct StarFieldView: View {
    private let stars: [CGPoint] = [
        .init(x: 0.14, y: 0.18), .init(x: 0.27, y: 0.24), .init(x: 0.83, y: 0.28), .init(x: 0.18, y: 0.52),
        .init(x: 0.72, y: 0.58), .init(x: 0.34, y: 0.74), .init(x: 0.62, y: 0.83), .init(x: 0.10, y: 0.88)
    ]

    var body: some View {
        GeometryReader { proxy in
            ForEach(Array(stars.enumerated()), id: \.offset) { index, point in
                Image(systemName: index.isMultiple(of: 2) ? "sparkles" : "circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: index.isMultiple(of: 2) ? 12 : 3, height: index.isMultiple(of: 2) ? 12 : 3)
                    .foregroundStyle(index.isMultiple(of: 2) ? Color(hex: "#D8C969") : .white)
                    .position(x: proxy.size.width * point.x, y: proxy.size.height * point.y)
            }
        }
    }
}

// 온보딩 선택 버튼 스타일
struct OnboardingOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(configuration.isPressed ? 0.14 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: "#BCE3F1"), lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// 주요 액션에 사용하는 채운 버튼 스타일
struct FilledPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.black.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: "#BCE3F1").opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(Capsule())
    }
}

// 보조 액션에 사용하는 버튼 스타일
struct SecondaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.black.opacity(0.75))
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(configuration.isPressed ? 0.78 : 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// 디자인에서 사용하는 hex 색상 변환 유틸
extension Color {
    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xff) / 255
        let green = Double((value >> 8) & 0xff) / 255
        let blue = Double(value & 0xff) / 255
        self.init(red: red, green: green, blue: blue)
    }
}
