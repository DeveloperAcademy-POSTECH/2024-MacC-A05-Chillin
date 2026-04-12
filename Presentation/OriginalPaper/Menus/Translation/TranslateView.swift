import SwiftUI
import Translation
import UniformTypeIdentifiers
import FirebaseAnalytics


@available(iOS 18.0, *)
struct TranslateView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @Environment(TranslationManager.self) private var translationManager
    
    @State private var configuration: TranslationSession.Configuration?
    
    private let pasteboard = UIPasteboard.general // 번역 결과 복사를 위한 클립보드
    
    var body: some View {
        @Bindable var translationManager = translationManager
        GeometryReader { geometry in
            Color.clear
                .translationTask(configuration, action: translationManager.translateAction)
                .popover(isPresented: $translationManager.isPopoverVisible) {
                    VStack(spacing: 10) {
                        ScrollView(showsIndicators: false) {
                            Text(translationManager.targetText)
                                .foregroundColor(.point2)
                                .lineSpacing(8)
                                .font(.system(size: 16, weight: .regular))
                                .frame(minWidth: translationManager.minBubbleWidth, maxWidth: translationManager.maxBubbleWidth, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true) // 텍스트 크기에 맞게 높이 조절
                                .background(
                                    GeometryReader { textGeometry in
                                        Color.clear
                                            .preference(key: ViewHeightKey.self, value: textGeometry.size.height)
                                    }
                                )
                        }
                        .frame(height: min(translationManager.textHeight, translationManager.maxBubbleHeight))
                        .frame(maxWidth: translationManager.maxBubbleWidth, maxHeight: translationManager.maxBubbleHeight)
                        .onPreferenceChange(ViewHeightKey.self) { height in
                            DispatchQueue.main.async {
                                translationManager.textHeight = height + 16
                            }
                        }
                        HStack(alignment: .center){
                            Spacer()
                            Text("번역 내용이 복사되었어요")
                                .padding(.horizontal, 8)
                                .reazyFont(.body2)
                                .foregroundColor(.gray600)
                                .opacity(translationManager.isCopySuccess ? 1 : 0)
                                .animation(.easeInOut(duration: 0.1), value: translationManager.isCopySuccess)
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
                .position(translationManager.updatedBubblePosition)
                .frame(height: min(translationManager.textHeight + 16, translationManager.maxBubbleHeight))
                .onAppear {
                    translationManager.bubblePositionForScreen(in: geometry.size)

                    // 번역 기능 초기화
                    triggerTranslation()
                    
                    // GA - 번역 화면 로그
                    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                        AnalyticsParameterScreenName: "번역 기능 실행",
                        AnalyticsParameterScreenClass: "TranslateView"
                    ])
                }
                .onChange(of: translationManager.selectedText) {
                    if !translationManager.selectedText.isEmpty {
                        translationManager.isTranslationComplete = false
                        translationManager.bubblePositionForScreen(in: geometry.size)
                        triggerTranslation()
                    }
                }
                .onDisappear {
                    translationManager.targetText = "" // 번역 결과 초기화
                    translationManager.isPopoverVisible = false // 팝업 숨기기
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

        // 사용자의 현재 언어에 따라 번역 타겟 언어 결정
        let targetLanguage: String
        switch Locale.currentLang() {
        case .ko:
            targetLanguage = "ko" // 한국어 사용자 -> 한국어로 번역
        case .ja:
            targetLanguage = "ja" // 일본어 사용자 -> 일본어로 번역
        case .en, .etc:
            targetLanguage = "en" // 영어 및 기타 언어 사용자 -> 영어로 번역
        }

        configuration = .init(source: nil, // 자동 언어 감지
                              target: Locale.Language(identifier: targetLanguage))
    }
    
    // 번역 복사 버튼
    public func copyToClipboard(){
        pasteboard.string = translationManager.targetText
        translationManager.isCopySuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 1.3)) {
                translationManager.isCopySuccess = false
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
