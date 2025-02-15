//
//  TagView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

// MARK: - [쿠로] 태그 뷰!
struct TagView: View {
    
    @State var isTagSelected: Bool = false
    @State var isTagExist: Bool = false
    
    let tags: [Tag] = [
        Tag(id: UUID(), title: "tag1", isSelected: false),
        Tag(id: UUID(), title: "tag2", isSelected: false)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.gray300
            
            GeometryReader { geometry in
                VStack(spacing: 1) {
                    
                    // 선택된 태그 화면
                    Group {
                        if isTagSelected {
                            SelectedTagView()
                        } else {
                            TagLEmptyView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray100)
                            .stroke(Color.gray400, lineWidth: 1)
                    )
                    
                    // 태그 선택하는 화면
                    VStack {
                        Group {
                            if isTagExist {
                                TagListView()
                            } else {
                                Text("아직 태그를 만들지 않았어요")
                                    .reazyFont(.text1)
                                    .foregroundStyle(.gray550)
                            }
                        }
                        .frame(minHeight: geometry.size.height * 0.35)
                        
                        // 편집 버튼
                        HStack {
                            Spacer()
                            Button(action: {
                                
                            }, label: {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(.gray)
                            })
                            .padding([.trailing, .bottom], 20)
                        }
                    }
                    .frame(maxWidth: .infinity,maxHeight: geometry.size.height * 0.4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray200)
                    )
                }
                .padding([.top, .horizontal], 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.all)
    }
}

struct TagLEmptyView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("태그로 원하는 논문을 찾아보세요")
                .reazyFont(.button1)
                .foregroundStyle(.gray550)
            Spacer()
            Button(action: {
                
            }, label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray600)
            })
        }
    }
}

struct SelectedTagView: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                Text("hi")
            }
        }
    }
}

struct TagListView: View {
    var body: some View {
        ScrollView(.vertical){
            VStack(spacing: 0) {
                Text("hi")
            }
        }
    }
}

#Preview {
    TagView()
}
