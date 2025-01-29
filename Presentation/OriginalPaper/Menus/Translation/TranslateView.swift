import SwiftUI
import Translation
import UniformTypeIdentifiers

@available(iOS 18.0, *)
struct TranslateView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State private var targetText = "" // 번역 결과 텍스트
    @State private var configuration: TranslationSession.Configuration?
    
    @State private var maxBubbleWidth: CGFloat = 400 // bubble 최대 너비
    @State private var minBubbleWidth: CGFloat = 250 // bubble 최대 너비
    @State private var maxBubbleHeight: CGFloat = 280 // bubble 최대 높이
    
    @State private var textHeight: CGFloat = 30 // 텍스트 높이 저장
    
    @State private var isPopoverVisible: Bool = false
    @State private var updatedBubblePosition: CGPoint = .zero // 조정된 bubble view 위치
    @State private var isTranslationComplete: Bool = false // 번역 완료 되었는지 확인해 뷰 새로 그리기 위한 flag
    
    private let pasteboard = UIPasteboard.general // 번역 결과 복사를 위한 클립보드
    @State private var isCopySuccess: Bool = false // 복사 성공 여부
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .foregroundStyle(.gray200)
                .translationTask(configuration) { session in
                    do {
                        let cleanedText = removeHyphen(in: mainPDFViewModel.selectedText)
                        let response = try await session.translate(cleanedText)
                        
                        targetText = response.targetText
                        if !targetText.isEmpty {
                            isTranslationComplete = true
                            isPopoverVisible = true
                        }
                    } catch {
                        print("translation do-catch")
                    }
                }
                .popover(isPresented: $isPopoverVisible) {
                    VStack(spacing: 10) {
                        // MARK: 번역 결과
                        ScrollView(showsIndicators: false) {
                            Text(targetText)
                                .foregroundColor(.point2)
                                .lineSpacing(8)
                                .font(.system(size: 16, weight: .regular))
                                .frame(minWidth: minBubbleWidth, maxWidth: maxBubbleWidth, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true) // 텍스트 크기에 맞게 높이 조절
                                .background(
                                    GeometryReader { textGeometry in
                                        Color.clear
                                            .preference(key: ViewHeightKey.self, value: textGeometry.size.height)
                                    }
                                )
                        }
                        .frame(height: min(textHeight, maxBubbleHeight))
                        .frame(maxWidth: maxBubbleWidth, maxHeight: maxBubbleHeight)
                        .onPreferenceChange(ViewHeightKey.self) { height in
                            DispatchQueue.main.async {
                                textHeight = height + 16
                            }
                        }
                        HStack(alignment: .center){
                            Spacer()
                            Text("번역 결과가 클립보드에 저장되었습니다")
                                .padding(.horizontal, 8)
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.gray600)
                                .opacity(isCopySuccess ? 1 : 0)
                                .animation(.easeInOut(duration: 0.1), value: isCopySuccess)
                            // MARK: 복사 버튼
                            Button(action: {
                                copyToClipboard()
                            }) {
                                RoundedRectangle(cornerRadius: 0)
                                    .foregroundStyle(.clear)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(.copyDark)
                                            .font(.system(size: 20))
                                            .foregroundStyle(.gray600)
                                    )
                            }
                        }
                        .foregroundStyle(.clear)
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 22)
                    
                }
                .position(updatedBubblePosition)
                .frame(height: min(textHeight + 16, maxBubbleHeight))
                .onAppear {
                    DispatchQueue.main.async {
                        bubblePositionForScreen(mainPDFViewModel.translateViewPosition, in: geometry.size)
                    }
                    triggerTranslation()
                }
                .onChange(of: mainPDFViewModel.selectedText) {
                    if !mainPDFViewModel.selectedText.isEmpty {
                        isTranslationComplete = false
                        DispatchQueue.main.async {
                            bubblePositionForScreen(mainPDFViewModel.translateViewPosition, in: geometry.size)
                        }
                        triggerTranslation()
                    }
                }
                .onChange(of: isTranslationComplete) {
                    if isTranslationComplete {
                        isPopoverVisible = true
                    }
                }
                .onDisappear {
                    targetText = "" // 번역 결과 초기화
                    isPopoverVisible = false // 팝업 숨기기
                    configuration?.invalidate()
                    configuration = nil
                }
        }
    }
    
    // 번역
    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            return
        }
        
        // 현재 언어는 영어 -> 한국어로 고정
        configuration = .init(source: Locale.Language(identifier: "en"),
                              target: Locale.Language(identifier: "ko"))
    }
    
    // TranslateView 위치 조정하는 함수
    private func bubblePositionForScreen(_ rect: CGRect, in screenSize: CGSize) {
        updatedBubblePosition = CGPoint(x: rect.midX, y: rect.minY)
        return
    }
    
    // 줄바꿈 전에 있는 '-'를 제거하는 함수
    func removeHyphen(in text: String) -> String {
        var result = ""
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        
        for line in lines {
            if line.hasSuffix("-") {
                result += line
            } else {
                result += line
            }
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // 번역 복사 버튼
    func copyToClipboard(){
        pasteboard.string = self.targetText
        isCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 1.0)) {
                isCopySuccess = false
            }
        }
    }
}

// 텍스트 높이 계산에 사용할 PreferenceKey
private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
