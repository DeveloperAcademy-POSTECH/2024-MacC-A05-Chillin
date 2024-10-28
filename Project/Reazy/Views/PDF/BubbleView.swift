import SwiftUI
import Translation

@available(iOS 18.0, *)
struct BubbleView: View {
    @Binding var selectedText: String
    @Binding var bubblePosition: CGRect
    
    @State private var targetText = ""
    
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        if #available(iOS 18.0, *) {
            // 18.0 이상 버전에서 보여줄 화면
            VStack (alignment: .center, spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray200)
                        .shadow(radius: 3)
                    
                    ScrollView() {
                        Text(targetText)
                            .disabled(true)
                            .font(.system(size: 14, weight: .regular))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .foregroundColor(.point2)
                            .lineSpacing(3)
                            .frame(maxWidth: 288, maxHeight: 288, alignment: .leading)
                    }
                    .frame(height: 288) // 원하는 높이로 조절
                }
            }
            .frame(width: 288, height: 288)
            .position(x: bubblePosition.maxX + 300, y: bubblePosition.midY - 100)
            .onAppear(){
                triggerTranslation()
            }
            .onChange(of: selectedText) { newValue in
                triggerTranslation() // selectedText가 변경될 때마다 triggerTranslation 호출
            }
            
            .translationTask(configuration) { session in
                do {
                    // selectedText에서 줄바꿈 전에 있는 '-' 제거하기
                    let cleanedText = removeHyphen(in: selectedText)
                    
                    // 번역 요청
                    let response = try await session.translate(cleanedText)
                    
                    // 번역된 결과로 뷰 업데이트
                    targetText = response.targetText
                } catch {
                    // TODO: 에러 해결
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
