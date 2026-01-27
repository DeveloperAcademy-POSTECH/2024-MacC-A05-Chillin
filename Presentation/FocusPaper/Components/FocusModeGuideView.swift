//
//  FocusModeGuideView.swift
//  Reazy
//
//  Created by 문인범 on 1/27/26.
//

import SwiftUI


struct FocusModeGuideView: View {
    let completeAction: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 21.47)
                .foregroundStyle(.gray200)
            
            VStack(spacing: 0) {
                Text("두 단 논문에 최적화된 읽기 모드입니다")
                    .reazyFont(.button1)
                    .padding(.top, 30)
                
                GuideAnimationView()
                    .padding(.top, 18)
                
                Spacer()
                
                seperator
                
                Button {
                    completeAction()
                } label: {
                    Text("확인")
                        .reazyFont(.text1)
                        .foregroundStyle(.primary1)
                        .frame(width: 460)
                        .padding(.vertical, 20)
                }
            }
        }
        .frame(width: 464, height: 379)
    }
    
    
    private var seperator: some View {
        Rectangle()
            .foregroundStyle(Color(hex: "#D9DBE9"))
            .frame(height: 1)
    }
}


private struct GuideAnimationView: View {
    private let animationPhase: [CGPoint] = [
        .init(x: 50, y: 60),
        .init(x: 50, y: 160),
        .init(x: 125, y: 60),
        .init(x: 125, y: 160),
        .init(x: 125, y: 161),
    ]
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.white)
            
            Rectangle()
                .stroke(lineWidth: 1)
                .foregroundStyle(.primary4)
            
            HStack(spacing: 6) {
                Rectangle()
                    .foregroundStyle(.primary3)
                    .frame(width: 68, height: 193)
                Rectangle()
                    .foregroundStyle(.primary3)
                    .frame(width: 68, height: 193)
            }
        }
        .frame(width: 175, height: 220)
        .overlay {
            ZStack {
                Rectangle()
                    .foregroundStyle(Color(hex: "5f5daa").opacity(0.2))
                Rectangle()
                    .stroke(lineWidth: 1)
                    .foregroundStyle(.primary1)
            }
            .frame(width: 79, height: 100)
            .phaseAnimator(animationPhase) { content, position in
                content
                    .position(position)
            } animation: { phase in
                switch phase {
                case .init(x: 50, y: 60): return nil
                case .init(x: 125, y: 60): return .easeInOut(duration: 1)
                default: return .easeInOut(duration: 2)
                }
            }
        }
    }
}


#Preview {
    FocusModeGuideView(completeAction: {})
}
