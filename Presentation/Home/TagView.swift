//
//  TagView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

// MARK: - [쿠로] 태그 뷰!
struct TagView: View {
    var body: some View {
        ZStack(alignment: .top) {
            Color.gray300
            VStack {
                HStack(spacing: 0) {
                    Text("태그로 원하는 논문을 찾아보세요")
                        .foregroundStyle(.gray550)
                    Spacer()
                    Button(action: {
                        
                    }, label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray600)
                    })
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(.gray100)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
            }
            .padding([.top,.horizontal], 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.all)
    }
}

struct TagListView: View {
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    TagView()
}
