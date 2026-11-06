import SwiftUI

// 일기 목록과 교환 목록을 보여주는 메인 홈 화면
struct MainHomeView: View {
    @ObservedObject var viewModel: AppViewModel
    @Binding var isPresentingComposer: Bool
    @State private var selectedDiary: DiaryEntry?
    @State private var isShowingProfile = false
    @State private var isShowingNotifications = false
    @State private var isShowingDiaryFilters = false
    @State private var isShowingRecoveryList = false
    @State private var selectedRecovery: DeletedDiaryRecovery?
    @State private var selectedExchange: ExchangeStory?

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: "#0A1018"), Color(hex: "#20395C")], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                tabBar
                pendingExchangeBanner
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

            if !viewModel.toastMessage.isEmpty {
                Text(viewModel.toastMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(Color.black.opacity(0.78))
                    .clipShape(Capsule())
                    .padding(.bottom, 92)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: $selectedDiary) { diary in
            DiaryDetailView(diary: diary, viewModel: viewModel)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isShowingProfile) {
            UserProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingNotifications) {
            PendingExchangeView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingDiaryFilters) {
            DiaryFilterView(viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingRecoveryList) {
            DeletedDiaryListView(viewModel: viewModel) { recovery in
                selectedRecovery = recovery
            }
        }
        .sheet(item: $selectedRecovery) { recovery in
            DiaryDetailView(diary: recovery.diary, viewModel: viewModel, isRecoveryMode: true, recovery: recovery)
                .presentationDetents([.large])
        }
        .sheet(item: $selectedExchange) { exchange in
            ExchangeStoryDetailView(story: exchange)
                .presentationDetents([.large])
        }
        .task {
            await viewModel.loadPendingExchanges()
            await viewModel.loadBlockedUsers()
            await viewModel.loadExchangeConnections()
        }
    }

    // 메인 화면 상단 헤더 영역
    private var header: some View {
        HStack {
            Button {
                isShowingProfile = true
            } label: {
                Image(systemName: "line.3.horizontal")
            }
            Text(viewModel.currentUser?.nickname ?? "bottleDiary")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                isShowingNotifications = true
            } label: {
                Image(systemName: viewModel.hasPendingExchangeNotification ? "bell.badge.fill" : "bell")
            }
            if viewModel.selectedTab == .myStories {
                Button {
                    isShowingDiaryFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
            if viewModel.selectedTab == .otherStories {
                Text("매칭 중")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.6))
                    .clipShape(Capsule())
            }

        }
        .animation(.easeInOut, value: viewModel.toastMessage)
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

    // 답장 대기 중인 일기가 있음을 홈 상단에 안내하는 배너
    @ViewBuilder
    private var pendingExchangeBanner: some View {
        if viewModel.hasPendingExchangeNotification {
            Button {
                isShowingNotifications = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.badge")
                    Text("답장 대기중인 일기가 있습니다.")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(Color(hex: "#25476D"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "#DCEFFF"))
            }
        }
    }

    // 선택된 탭에 따라 목록을 보여주는 본문 영역
    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .myStories:
            ScrollView {
                VStack(spacing: 14) {
                    if !viewModel.diaryHistoryMessage.isEmpty {
                        HStack(spacing: 10) {
                            Text(viewModel.diaryHistoryMessage)
                                .font(.footnote)
                                .foregroundStyle(Color(hex: "#FFD7D7"))
                            Spacer()
                            Button("재시도") {
                                Task { try? await viewModel.loadDiaryHistory(reset: true) }
                            }
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 4)
                    }

                    if !viewModel.recoverableDiaries.isEmpty {
                        Button {
                            viewModel.removeExpiredRecoveries()
                            isShowingRecoveryList = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.uturn.backward.circle")
                                Text("삭제된 일기 복구 (\(viewModel.recoverableDiaries.count))")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(Color.black.opacity(0.22))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if viewModel.diaryEntries.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 32))
                                .foregroundStyle(Color(hex: "#A9D5F0"))
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
                        .onAppear {
                            if diary.id == viewModel.diaryEntries.last?.id,
                               viewModel.hasMoreDiaryHistory {
                                Task { try? await viewModel.loadDiaryHistory(reset: false) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 120)
            }
        case .otherStories:
            VStack(spacing: 0) {
                exchangeNotice

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
                                    selectedExchange = story
                                } disconnect: {
                                    viewModel.closeExchange(story)
                                } block: {
                                    viewModel.blockExchange(story)
                                } rematch: {
                                    viewModel.rematchExchange(story)
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

    // 교환 답장 기한 안내 문구
    private var exchangeNotice: some View {
        Text("24시간 이내에 답장하지 않으면 서로의 연결이 종료됩니다.")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.78))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, 12)
    }
}
