import SwiftUI

// 일기 교환이 성사된 뒤 보여주는 결과 화면
struct ExchangeResultView: View {
    let story: ExchangeStory
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#05080D"), Color(hex: "#223E66")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: proxy.size.height < 700 ? 20 : 28) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Spacer()
                        }
                        .foregroundStyle(.white)

                        Spacer(minLength: proxy.size.height < 700 ? 20 : 40)

                        Text("오늘까지\n\(story.daysRemaining)일째 교환이에요")
                            .font(.system(size: proxy.size.height < 700 ? 28 : 34, weight: .bold))
                            .minimumScaleFactor(0.85)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                        Text("“")
                            .font(.system(size: proxy.size.height < 700 ? 40 : 50))
                            .foregroundStyle(.white)

                        Text("각자의 마음을 판단없이\n호기심으로 바라보세요.")
                            .font(.system(size: proxy.size.height < 700 ? 20 : 24, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.9))

                        Spacer(minLength: proxy.size.height < 700 ? 24 : 40)

                        VStack(spacing: 12) {
                            Button("교환하기") {
                                dismiss()
                            }
                            .buttonStyle(FilledPrimaryButtonStyle())

                            Button("나만 보기") {
                                dismiss()
                            }
                            .buttonStyle(SecondaryFilledButtonStyle())
                        }
                    }
                    .frame(minHeight: proxy.size.height - proxy.safeAreaInsets.top - proxy.safeAreaInsets.bottom)
                    .padding(.horizontal, 24)
                    .padding(.top, proxy.safeAreaInsets.top + 22)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + 22)
                }
            }
        }
    }
}

// 교환 결과 화면 미리보기
struct ExchangeResultView_Previews: PreviewProvider {
    static var previews: some View {
        ExchangeResultView(
            story: ExchangeStory(
                partnerName: "익명의 친구",
                daysRemaining: 3,
                myEntry: DiaryEntry(
                    dateText: "오늘",
                    title: "나의 하루",
                    content: "오늘 일기를 썼다.",
                    mood: "덤덤"
                ),
                partnerEntry: DiaryEntry(
                    dateText: "오늘",
                    title: "상대의 하루",
                    content: "상대방도 조용한 하루를 보냈다.",
                    mood: "덤덤"
                ),
                isActive: true
            ),
            dismiss: {}
        )
        .previewDevice("iPhone 16 Pro")
    }
}
