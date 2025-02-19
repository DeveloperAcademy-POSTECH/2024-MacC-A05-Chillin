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
    @State private var popover = false
    @EnvironmentObject private var tagViewModel: TagViewModel
    
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
                            if tagViewModel.isTagExist {
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
                            EllipsisView(ellipsisAction: {
                                popover.toggle()
                            })
                            //TODO: - 팝오버 띄우기
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
    @EnvironmentObject private var tagViewModel: TagViewModel
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical){
                
                // TODO: 태그 생기면 연결
                DynamicCellLayout(data: tagViewModel.tags, action: { title in
                    tagViewModel.cellTapped(title: title)
                }, screenWidth: geometry.size.width)
                .border(Color.blue, width: 2)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                //Spacer().frame(width: 20)
//                Rectangle()
//                    .frame(width: geometry.size.width, height: 100)
//                    .border(Color.red, width: 2)
            }
        }
    }
}

#Preview {
    TagView()
}
