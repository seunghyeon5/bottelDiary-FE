import SwiftUI

// 일기 목록과 교환 목록을 보여주는 메인 홈 화면
struct MainHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var isPresentingComposer: Bool
    @State private var selectedDiary: DiaryEntry?

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "#0A1018"), Color(hex: "#20395C")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabBar
                content
            }

            Button {
                isPresentingComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color(hex: "#A9D5F0"))
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 8)
            }
            .padding(.bottom, 28)
        }
        .sheet(item: $selectedDiary) { diary in
            DiaryDetailView(diary: diary)
                .presentationDetents([.large])
        }
    }

    // 메인 화면 상단 헤더 영역
    private var header: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
            Spacer()
            if viewModel.selectedTab == .otherStories {
                Text("매칭 중")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.6))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
        .background(Color.black.opacity(0.22))
    }

    // 내 이야기 / 다른 이야기 전환 탭 영역
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(BottleDiaryTab.allCases, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.selectedTab == tab ? .white : .white.opacity(0.6))
                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? .white : .clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    // 선택된 탭에 따라 목록을 보여주는 본문 영역
    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .myStories:
            ScrollView {
                VStack(spacing: 14) {
                    if !viewModel.diaryHistoryMessage.isEmpty {
                        Text(viewModel.diaryHistoryMessage)
                            .font(.footnote)
                            .foregroundStyle(Color(hex: "#FFD7D7"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    if viewModel.diaryEntries.isEmpty {
                        VStack(spacing: 10) {
                            Text("아직 작성한 일기가 없습니다.")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("아래 버튼으로 오늘의 이야기를\n가볍게 남겨보세요.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 56)
                    }

                    ForEach(viewModel.diaryEntries) { diary in
                        Button {
                            selectedDiary = diary
                        } label: {
                            DiaryCardView(diary: diary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        case .otherStories:
            if viewModel.exchangeStories.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Text("아직 연결된 사람이 없습니다.")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("당신의 하루를 적어서\n곧 누군가의 하루와 마주해보세요.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.72))
                    Spacer()
                }
                .padding(.bottom, 80)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.exchangeStories) { story in
                            ExchangeCardView(story: story) {
                                viewModel.closeExchange(story)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 120)
                }
            }
        }
    }
}
