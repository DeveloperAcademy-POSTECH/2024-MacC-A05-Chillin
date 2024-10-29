import SwiftUI
import Translation

@available(iOS 18.0, *)
struct BubbleView: View {
    @Binding var selectedText: String
    @Binding var bubblePosition: CGRect
    
    @State private var targetText = "" // 번역 결과 텍스트
    @State private var configuration: TranslationSession.Configuration?
    
    @State private var maxBubbleWidth: CGFloat = 400 // bubble 최대 너비
    @State private var maxBubbleHeight: CGFloat = 280 // bubble 최대 높이
    @State private var textHeight: CGFloat = 0 // 텍스트 높이 저장
    @State private var textWidth: CGFloat = 100 // 텍스트 너비 저장
    
    // 말풍선 붙는 위치
    enum BubbleDirection {
        case left, right, bottom
    }
    
    @State private var bubbleDirection: BubbleDirection = .left
    
    @State private var updatedBubblePosition: CGPoint = .zero // 조정된 bubble view 위치
    @State private var isTranslationComplete: Bool = false // 번역 완료 되었는지 확인해 뷰 새로 그리기 위한 flag
    
    var body: some View {
        if #available(iOS 18.0, *) {
            // 18.0 이상 버전에서 보여줄 화면
            GeometryReader { geometry in
                    VStack(alignment: .center, spacing: 0) {
                        if isTranslationComplete {
                            ZStack (alignment: .center) {
                                // 배경에 깔릴 테두리 용 삼각형
                                Image(systemName: "triangle.fill")
                                    .resizable()
                                    .foregroundStyle(.primary3)
                                    .frame(width: 30, height: 22) // 크기 지정 (테두리 역할이라 + 2씩)
                                    .rotationEffect(
                                        Angle(degrees: {
                                            switch bubbleDirection {
                                            case .left:
                                                return 90
                                            case .right:
                                                return 270
                                            case .bottom:
                                                return 0
                                            }
                                        }())
                                    )
                                    .offset(
                                        x: {
                                            switch bubbleDirection {
                                            case .left:
                                                return (min(textWidth, maxBubbleWidth) / 2) + 2
                                            case .right:
                                                return -(min(textWidth, maxBubbleWidth) / 2) - 2
                                            case .bottom:
                                                return 0
                                            }
                                        }(),
                                        y: bubbleDirection == .bottom ? -(min(textHeight, maxBubbleHeight) / 2) - 2 : 0 // 전체 높이의 중간에 화살표가 오게 조정
                                    )
                                    .shadow(color: Color(hex: "#767676").opacity(0.25), radius: 6, x: 0, y: 2)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.gray200)
                                    .stroke(.primary3, lineWidth: 1)
                                    .frame(width: min(textWidth, maxBubbleWidth), height: min(textHeight, maxBubbleHeight))
                                    .shadow(color: Color(hex: "#767676").opacity(0.25), radius: 6, x: 0, y: 2)
                                
                                // 말풍선 옆에 붙어있는 삼각형
                                Image(systemName: "triangle.fill")
                                    .resizable()
                                    .foregroundStyle(.gray200)
                                    .frame(width: 28, height: 20) // 크기 지정
                                    .rotationEffect(
                                        Angle(degrees: {
                                            switch bubbleDirection {
                                            case .left:
                                                return 90
                                            case .right:
                                                return 270
                                            case .bottom:
                                                return 0
                                            }
                                        }())
                                    )
                                    .offset(
                                        x: {
                                            switch bubbleDirection {
                                            case .left:
                                                return (min(textWidth, maxBubbleWidth) / 2) + 1
                                            case .right:
                                                return -(min(textWidth, maxBubbleWidth) / 2) - 1
                                            case .bottom:
                                                return 0
                                            }
                                        }(),
                                        y: bubbleDirection == .bottom ? -(min(textHeight, maxBubbleHeight) / 2) - 2 : 0 // 높이의 반만큼 화살표 위로 이동
                                    )
                                
                                ScrollView() {
                                    VStack {
                                        Text(targetText)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(.point2)
                                            .lineSpacing(3)
                                            .padding(.vertical, 14)
                                            .padding(.horizontal, 18)
                                            .background(
                                                GeometryReader { textGeometry in
                                                    Color.clear
                                                        .preference(key: ViewHeightKey.self, value: textGeometry.size.height)
                                                }
                                            )
                                    }
                                    .frame(maxWidth: maxBubbleWidth) // maxBubbleWidth로 최대 너비 설정
                                }
                                .frame(width: min(textWidth, maxBubbleWidth), height: min(textHeight, maxBubbleHeight))
                            }
                        }
                    }
                    .position(updatedBubblePosition)
                    .onAppear {
                        bubblePositionForScreen(bubblePosition, in: geometry.size)
                        textWidth = bubblePosition.width * 1.5 // 글자 수 적을 때 너비 여유롭게
                        triggerTranslation()
                    }
                    .onChange(of: selectedText) { _ in
                        isTranslationComplete = false // 번역 완료 되었을 때 뷰 다시 그리게 false 처리
                        bubblePositionForScreen(bubblePosition, in: geometry.size)
                        textWidth = bubblePosition.width * 1.5
                        triggerTranslation()
                    }
                    .onPreferenceChange(ViewHeightKey.self) { height in
                        textHeight = height
                    }
                    .translationTask(configuration) { session in
                        do {
                            let cleanedText = removeHyphen(in: selectedText)
                            let response = try await session.translate(cleanedText)
                            targetText = response.targetText
                            if !targetText.isEmpty {
                                isTranslationComplete = true
                            }
                        } catch {
                            print(" 번역 중 에러 발생 ")
                        }
                    }
                
            }
        } else {
            // TODO: - 18.0 미만 버전에서 보여줄 화면
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
        
        // 현재 언어는 영어 -> 한국어로 고정
        configuration = .init(source: Locale.Language(identifier: "en"),
                              target: Locale.Language(identifier: "ko"))
    }
    
    // BubbleView 위치 조정하는 함수
    private func bubblePositionForScreen(_ rect: CGRect, in screenSize: CGSize) {
        
        if rect.width > (screenSize.width / 2) { // 선택 영역이 차지하는 범위가 1/2 이상이면
            // 말풍선이 선택 영역 아래에 붙음
            bubbleDirection = .bottom
            updatedBubblePosition = CGPoint(x: rect.midX, y: rect.maxY) // 아래로 이동
        } else if rect.maxX > (screenSize.width / 2) && rect.minX > (screenSize.width / 3) {
            // 말풍선이 선택 영역 왼쪽에 붙음
            bubbleDirection = .left
            updatedBubblePosition = CGPoint(x: rect.minX - maxBubbleWidth + 150, y: rect.midY - 100)
        } else if rect.maxX < (screenSize.width / 2) || rect.minX > (screenSize.width / 3){
            // 말풍선이 선택 영역 오른쪽에 붙음
            bubbleDirection = .right
            updatedBubblePosition = CGPoint(x: rect.maxX + maxBubbleWidth - 150, y: rect.midY - 100)
        } else {
            // 말풍선이 선택 영역 아래에 붙음
            bubbleDirection = .bottom
            updatedBubblePosition = CGPoint(x: rect.midX, y: rect.maxY) // 아래로 이동
        }
        return
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
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// 텍스트 높이 계산에 사용할 PreferenceKey
struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
