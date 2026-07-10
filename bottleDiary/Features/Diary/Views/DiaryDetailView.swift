import SwiftUI

// 내 이야기 목록에서 선택한 일기의 상세 내용을 보여주는 시트 화면
struct DiaryDetailView: View {
    let diary: DiaryEntry
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEditNotice = false
    @State private var isShowingDeleteDialog = false
    @State private var isShowingDeleteNotice = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#DCEFFF").ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(diary.dateText)
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(Color.black.opacity(0.6))

                                    Text(diary.title)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.black)
                                }

                                Spacer()

                                Text(diary.mood)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.65))
                                    .clipShape(Capsule())
                            }

                            Rectangle()
                                .fill(Color.black.opacity(0.12))
                                .frame(height: 1)

                            Text(diary.content)
                                .font(.body)
                                .foregroundStyle(.black.opacity(0.82))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .lineSpacing(6)
                        }
                        .padding(20)
                    }

                    actionBar
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.black)
                    }
                }
            }
            .alert("수정 기능 준비 중", isPresented: $isShowingEditNotice) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("다음 단계에서 일기 수정 기능을 연결할 예정이에요.")
            }
            .confirmationDialog("이 일기를 삭제할까요?", isPresented: $isShowingDeleteDialog, titleVisibility: .visible) {
                Button("삭제", role: .destructive) {
                    isShowingDeleteNotice = true
                }
                Button("취소", role: .cancel) { }
            } message: {
                Text("현재는 삭제 버튼 자리만 먼저 잡아둔 초안 상태예요.")
            }
            .alert("삭제 기능 준비 중", isPresented: $isShowingDeleteNotice) {
                Button("확인", role: .cancel) { }
            } message: {
                Text("삭제 API가 연결되면 여기서 실제 삭제가 동작하게 할 수 있어요.")
            }
        }
    }

    // 상세 화면 하단의 수정/삭제 액션 버튼 영역
    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                isShowingEditNotice = true
            } label: {
                Text("수정")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#25476D"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button {
                isShowingDeleteDialog = true
            } label: {
                Text("삭제")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(hex: "#D86A6A"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(Color.white.opacity(0.18))
    }
}
