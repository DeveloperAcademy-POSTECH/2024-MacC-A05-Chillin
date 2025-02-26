//
//  RenamePaperTitleView.swift
//  Reazy
//
//  Created by 문인범 on 2/19/25.
//

import SwiftUI


/**
 논문 이름 재설정 View
 */
public struct RenamePaperTitleView: View {
    let paperInfo: PaperInfo
    let cancelAction: () -> Void
    let completeAction: (String) -> Void
    
    @State private var text: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(
        paperInfo: PaperInfo,
        cancelAction: @escaping () -> Void,
        completeAction: @escaping (String) -> Void
    ) {
        self.paperInfo = paperInfo
        self.cancelAction = cancelAction
        self.completeAction = completeAction
        self.text = paperInfo.title
    }
    
    public var body: some View {
        ZStack {
            Color.black
                .opacity(0.5)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Button {
                        cancelAction()
                        isTextFieldFocused = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(.gray100)
                    .padding(28)
                    
                    Spacer()
                    
                    Button(action: {
                        completeAction(text)
                        isTextFieldFocused = false
                    }) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray100, lineWidth: 1)
                            .frame(width: 68, height: 36)
                            .overlay {
                                Text("완료")
                                    .reazyFont(.button1)
                                    .foregroundStyle(.gray100)
                            }
                    }
                    .padding(28)
                }
                
                Spacer()
            }
            HStack(spacing: 54) {
                Image(uiImage: .init(data: paperInfo.thumbnail)!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 196)
                
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .frame(width: 400, height: 52)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray400)
                            .frame(width: 400, height: 52)
                    }
                    .frame(width: 400, height: 52)
                    .overlay(alignment: .center) {
                        TextField("제목을 입력해주세요.", text: $text, axis: .horizontal)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .font(.custom(ReazyFontType.pretendardMediumFont, size: 16))
                            .foregroundStyle(.gray800)
                    }
                    .overlay(alignment: .trailing) {
                        if !self.text.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                                .background(.gray100)
                                .padding(.trailing, 10)
                                .onTapGesture {
                                    text = ""
                                }
                        }
                    }
                    .focused($isTextFieldFocused)
                    
                    Text("논문 제목을 입력해 주세요")
                        .reazyFont(.button1)
                        .foregroundStyle(.comment)
                }
            }
        }
    }
}
