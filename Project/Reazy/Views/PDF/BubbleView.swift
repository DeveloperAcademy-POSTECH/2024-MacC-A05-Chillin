import SwiftUI
import Translation

@available(iOS 18.0, *)
struct BubbleView: View {
    @Binding var selectedText: String
    @Binding var bubblePosition: CGRect
    
    @State private var targetText = ""
    @State private var configuration: TranslationSession.Configuration?
    
    var maxBubbleWidth: CGFloat = 288 // bubble 최대 너비
    var maxBubbleHeight: CGFloat = 240 // bubble 최대 높이
    @State private var textHeight: CGFloat = 0 // 텍스트 높이 저장
    @State private var textWidth: CGFloat = 0 // 텍스트 높이 저장

    var body: some View {
        if #available(iOS 18.0, *) {
            // 18.0 이상 버전에서 보여줄 화면
            GeometryReader { geometry in
                VStack(alignment: .center, spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.gray200)
                            .shadow(color: Color(hex: "#383582").opacity(0.25), radius: 6, x: 0, y: 2)
                            .frame(width: textWidth, height: min(textHeight, maxBubbleHeight))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.clear)
                                    .stroke(Color(hex: "#DADDEF"), lineWidth: 1) // 외곽선 추가
                            )
                        
                        ScrollView() {
                            Text(targetText)
                                .font(.system(size: 14, weight: .regular))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .foregroundColor(.point2)
                                .lineSpacing(3)
                                .frame(width: maxBubbleWidth, alignment: .center)
                                .background(
                                    GeometryReader { textGeometry in
                                        Color.clear
                                            .preference(key: ViewHeightKey.self, value: textGeometry.size.height)
                                            .preference(key: ViewWidthKey.self, value: textGeometry.size.width)
                                    }
                                )
                        }
                        .frame(width: maxBubbleWidth, height: min(textHeight, maxBubbleHeight))
                    }
                }
                .position(bubblePositionForScreen(bubblePosition, in: geometry.size)) // 업데이트된 위치 계산 함수 사용
                .onAppear {
                    triggerTranslation()
                }
                .onChange(of: selectedText) { _ in
                    triggerTranslation()
                }
                .onPreferenceChange(ViewHeightKey.self) { height in
                    textHeight = height
                }
                .onPreferenceChange(ViewWidthKey.self) { width in
                    textWidth = width
                }
                .translationTask(configuration) { session in
                    do {
                        let cleanedText = removeHyphen(in: selectedText)
                        let response = try await session.translate(cleanedText)
                        targetText = response.targetText
                    } catch {
                        // TODO: 에러 처리
                    }
                }
            }
        } else {
            // 18.0 미만 버전에서 보여줄 화면 
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray200)
                        .shadow(radius: 3)
                    
                    Text("번역 기능은 ios 18.0 이상 업데이트 후 사용 가능합니다.")
                        .font(.system(size: 12))
                        .padding(8)
                        .foregroundColor(.point2)
                }
                .frame(maxWidth: 680)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } // 화면 중간 상단에 고정
    }
    // 번역
    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            
            return
        }

        configuration = .init(source: Locale.Language(identifier: "en"),
                              target: Locale.Language(identifier: "ko"))
    }
    
    //  BubbleView 위치 조정하는 함수
    private func bubblePositionForScreen(_ rect: CGRect, in screenSize: CGSize) -> CGPoint {
        var x = rect.midX
        var y = rect.midY

        if rect.maxX + maxBubbleWidth > screenSize.width { // 오른쪽 벗어남
            x = rect.minX - maxBubbleWidth + 100
        } else {
            x = rect.maxX + maxBubbleWidth - 100
        }

        y = rect.midY - 100 // scrollview 높이
        return CGPoint(x: x, y: y)
    }

    // 줄바꿈 전에 있는 '-'를 제거하는 함수
    func removeHyphen(in text: String) -> String {
        var result = ""
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        
        for line in lines {
            if line.hasSuffix("-") {
                result += line.dropLast() // 줄 끝 '-'를 제거하고 줄바꿈 추가
            } else {
                result += line + "\n" // '-'가 없는 줄은 그대로 추가
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines) // 불필요한 공백 제거
    }
}

// 텍스트 높이 계산에 사용할 PreferenceKey
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ViewWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
