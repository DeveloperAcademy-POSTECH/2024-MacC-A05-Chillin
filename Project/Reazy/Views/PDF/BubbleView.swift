import SwiftUI

struct BubbleView: View {
    var selectedText: String
    var position: CGPoint

    var body: some View {
        ZStack {
            // 말풍선 배경
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray100)
                .shadow(radius: 3)
                .overlay(Triangle().fill(Color.white)) // 삼각형 추가
                .background(.clear)

            // 선택된 텍스트
            Text(selectedText)
                .font(.system(size: 12))
                .padding(8) // 패딩 추가
                .foregroundColor(.black)
        }
        .background(.clear)
        .frame(maxWidth: 312) // 최대 너비 설정
        .position(position) // 위치 설정
        .fixedSize(horizontal: false, vertical: true) // 높이에 맞춰서 조정
    }
}

// 삼각형 모양
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
