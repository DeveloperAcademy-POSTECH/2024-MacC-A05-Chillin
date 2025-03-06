//
//  TagControlView.swift
//  Reazy
//
//  Created by 문인범 on 3/6/25.
//

import SwiftUI



struct TagControlView: View {
    @State private var viewStatus: Bool = false
    @FocusState private var textFieldFocus: Bool
    
    
    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 40) {
                Image(.testThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                
                VStack(spacing: 0) {
                    TagInputTextField(textFieldFocus: $textFieldFocus)
                    
                    ZStack {
                        
                        VStack {
                            Text("태그를 만들거나 추가할 태그를 검색하세요")
                                .reazyFont(.text1)
                                .foregroundStyle(.comment)
                                .padding(.top, 14)
                                .padding(.bottom, 20)
                            
                            ForEach(0 ..< 7) { _ in
                                IncludedTagView()
                            }
                        }
                        
                        if textFieldFocus {
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundStyle(.gray200)
                                .frame(width: 400, height: 240)
                        }
                    }
                }
            }
        }
    }
}




private struct TagInputTextField: View {
    @State private var text: String = ""
    
    var textFieldFocus: FocusState<Bool>.Binding
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.gray100)
            
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 1)
                .foregroundStyle(.gray400)
            
            HStack(spacing: 0) {
                TextField("새로운 태그", text: $text)
                    .focused(textFieldFocus)
                    .reazyFont(.text1)
                    .foregroundStyle(.gray800)
                    .lineLimit(1)
                
                Button {
                    textFieldFocus.wrappedValue.toggle()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary1)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
        }
        .frame(width: 400, height: 52)
    }
}


private struct IncludedTagView: View {
    var body: some View {
        Group {
            HStack(spacing: 0) {
                Text("테스트태그")
                    .reazyFont(.body3)
                    .foregroundStyle(.gray800)
                    .frame(height: 28)
                    .padding(.horizontal, 9)
                    .background {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(.primary3)
                    }
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray100)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
        }
        .frame(width: 400)
        .padding(.bottom, 12)
    }
}


private struct NewTagSearchResultView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.gray200)
                .frame(width: 400, height: 240)
            
            Text(
                """
                새로운 태그를 만들거나
                추가할 태그를 검색하세요
                최대 30자
                """
            )
            .reazyFont(.body1)
            .multilineTextAlignment(.center)
            .foregroundStyle(.gray600)
        }
    }
}


#Preview {
    NewTagSearchResultView()
}
