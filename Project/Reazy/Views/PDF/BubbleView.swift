import SwiftUI
import Translation

@available(iOS 18.0, *)
struct BubbleView: View {
    @Binding var selectedText: String
    @State private var targetText = ""
    
    // Define a configuration.
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        if #available(iOS 18.0, *) {
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray100)
                        .shadow(radius: 3)
                        .overlay(Triangle().fill(Color.white))
                    
                    Text(targetText)
                        .font(.system(size: 12))
                        .padding(8)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: 680)
                .fixedSize(horizontal: false, vertical: true)
            }
            .onAppear(){
                triggerTranslation()
            }
            .onChange(of: selectedText) { oldValue, newValue in
                triggerTranslation() // selectedText가 변경될 때마다 triggerTranslation 호출
            }
            
            // 번역
            .translationTask(configuration) { session in
                do {
                    let response = try await session.translate(selectedText)
                    
                    // 번역된 결과로 뷰 업데이트
                    targetText = response.targetText
                } catch {
                    // TODO: 에러 해결
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            // 18.0 미만 버전에서 보여줄 화면 
            VStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray100)
                        .shadow(radius: 3)
                        .overlay(Triangle().fill(Color.white))
                    
                    Text("번역 기능은 ios 18.0 이상 업데이트 후 사용 가능합니다.")
                        .font(.system(size: 12))
                        .padding(8)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: 680)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } // 화면 중간 상단에 고정
    }
    private func triggerTranslation() {
        guard configuration == nil else {
            configuration?.invalidate()
            
            return
        }

        configuration = .init(source: Locale.Language(identifier: "en"),
                              target: Locale.Language(identifier: "ko"))
    }
}

// 삼각형 모양 필요 시 사용
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - 10, y: rect.maxY)) // 삼각형 왼쪽 점
        path.addLine(to: CGPoint(x: rect.midX + 10, y: rect.maxY)) // 삼각형 오른쪽 점
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + 10)) // 삼각형 아래 점
        path.closeSubpath()
        return path
    }
}
