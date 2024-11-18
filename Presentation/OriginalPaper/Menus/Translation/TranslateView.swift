import SwiftUI
import Translation

@available(iOS 18.0, *)
struct TranslateView: View {
    @EnvironmentObject private var flotingViewModel: FloatingViewModel

    @Binding var selectedText: String
    @Binding var translatePosition: CGRect

    @State private var targetText = "" // 번역 결과 텍스트
    @State private var configuration: TranslationSession.Configuration?

    @State private var maxBubbleWidth: CGFloat = 400 // bubble 최대 너비
    @State private var maxBubbleHeight: CGFloat = 280 // bubble 최대 높이

    @State private var textHeight: CGFloat = 30 // 텍스트 높이 저장

    @State private var isPopoverVisible: Bool = false
    @State private var updatedBubblePosition: CGPoint = .zero // 조정된 bubble view 위치
    @State private var isTranslationComplete: Bool = false // 번역 완료 되었는지 확인해 뷰 새로 그리기 위한 flag

    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .foregroundStyle(.gray200)
                .popover(isPresented: $isPopoverVisible, arrowEdge: .bottom) {
                    ZStack(alignment: .top) {
                        ScrollView(showsIndicators: false) {
                            Text(targetText)
                                .foregroundColor(.point2)
                                .lineSpacing(8)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .font(.system(size: 16, weight: .regular))
                                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
                                .background(
                                    GeometryReader { textGeometry in
                                        Color.clear
                                            .preference(key: ViewHeightKey.self, value: textGeometry.size.height)
                                    }
                                )
                        }
                        .padding(.bottom, 14)
                        .padding(.horizontal, 16)
                        .frame(height: min(textHeight, maxBubbleHeight))
                        .frame(maxWidth: maxBubbleWidth, maxHeight: maxBubbleHeight) // ScrollView 높이 제한
                        .onPreferenceChange(ViewHeightKey.self) { height in
                            DispatchQueue.main.async {
                                textHeight = height
                            }
                        }
                    }
                }
                .frame(maxHeight: maxBubbleHeight)
                .position(updatedBubblePosition)
                .translationTask(configuration) { session in
                    do {
                        let cleanedText = removeHyphen(in: selectedText)
                        let response = try await session.translate(cleanedText)
                        
                        targetText = response.targetText
                        if !targetText.isEmpty {
                            isTranslationComplete = true
                            isPopoverVisible = true
                        }
                    } catch {
                        print(" 번역 중 에러 발생 ")
                    }
                }
                .onAppear {
                    bubblePositionForScreen(translatePosition, in: geometry.size)
                    triggerTranslation()
                }
                .onChange(of: selectedText) {
                    isTranslationComplete = false
                    bubblePositionForScreen(translatePosition, in: geometry.size)
                    triggerTranslation()
                }
                .onChange(of: isTranslationComplete) {
                    if isTranslationComplete {
                        isPopoverVisible = true
                    }
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
}

// 텍스트 높이 계산에 사용할 PreferenceKey
private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
