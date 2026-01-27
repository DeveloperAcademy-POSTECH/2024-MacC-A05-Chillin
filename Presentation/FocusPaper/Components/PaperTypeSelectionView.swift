//
//  PaperTypeSelectionView.swift
//  Reazy
//
//  Created by 문인범 on 1/26/26.
//

import SwiftUI


fileprivate enum CurrentColumn {
    case two
    case three
}

struct PaperTypeSelectionView: View {
    @State private var selectedColumn: CurrentColumn?
    
    let complete: (Bool) -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 21.47)
                .foregroundStyle(.gray200)
            
            VStack(spacing: 0) {
                Text("논문 형식을 선택해주세요")
                    .reazyFont(.button1)
                    .foregroundStyle(Color(hex: "#3C3D4B"))
                    .padding(.top, 23)
                    .padding(.bottom, 35)
                
                
                HStack {
                    TwoColumnPaperView(selectedColumn: $selectedColumn)
                        .onTapGesture {
                            selectedColumn = .two
                        }
                    
                    Spacer()
                    
                    ThreeColumnPaperView(selectedColumn: $selectedColumn)
                        .onTapGesture {
                            selectedColumn = .three
                        }
                }
                .padding(.horizontal, 46)
                
                Spacer()
                seperator
                
                Button {
                    complete(selectedColumn == .two ? true : false)
                } label: {
                    Text("확인")
                        .reazyFont(.text1)
                        .frame(width: 460)
                        .padding(.vertical, 20)
                }
                .disabled( selectedColumn == nil )
            }
        }
        .frame(width: 464, height: 379)
    }
    
    
    private var seperator: some View {
        Rectangle()
            .fill(Color.init(hex: "#D9DBE9"))
            .frame(height: 1)
    }
}


private struct TwoColumnPaperView: View {
    @Binding var selectedColumn: CurrentColumn?
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 136, height: 169)
                Rectangle()
                    .stroke(lineWidth: 1)
                    .foregroundStyle(.primary4)
                    .frame(width: 136, height: 169)
                
                HStack(spacing: 5) {
                    Rectangle()
                        .frame(width: 53, height: 150)
                    Rectangle()
                        .frame(width: 53, height: 150)
                }
                .foregroundStyle(.primary3)
            }
            
            Text("두 단")
                .font(.custom(ReazyFontType.pretendardSemiboldFont, size: 17.18))
                .foregroundStyle(Color(hex: "#3C3D4B"))
        }
        .overlay {
            if selectedColumn == .two {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(Color(hex: "#5F5DAA").opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.primary1)
                }
                .frame(width: 194, height: 239)
            }
        }
    }
}


private struct ThreeColumnPaperView: View {
    @Binding var selectedColumn: CurrentColumn?
    
    var body: some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundStyle(.white)
                    .frame(width: 136, height: 169)
                Rectangle()
                    .stroke(lineWidth: 1)
                    .foregroundStyle(.primary4)
                    .frame(width: 136, height: 169)
                
                HStack(spacing: 5) {
                    Rectangle()
                        .frame(width: 36, height: 150)
                    Rectangle()
                        .frame(width: 36, height: 150)
                    Rectangle()
                        .frame(width: 36, height: 150)
                }
                .foregroundStyle(.primary3)
                .padding(10)
            }
            
            Text("세 단")
                .font(.custom(ReazyFontType.pretendardSemiboldFont, size: 17.18))
                .foregroundStyle(Color(hex: "#3C3D4B"))
        }
        .overlay {
            if selectedColumn == .three {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(Color(hex: "#5F5DAA").opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.primary1)
                }
                .frame(width: 194, height: 239)
            }
        }
    }
}


#Preview {
    PaperTypeSelectionView(complete: { _ in })
}




