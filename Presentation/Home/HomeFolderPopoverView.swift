//
//  HomeFolderPopoverView.swift
//  Reazy
//
//  Created by 문인범 on 3/26/25.
//

import SwiftUI


struct HomeFolderPopoverView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .frame(width: 200, height: 171)
            .foregroundStyle(.white)
            .overlay {
                VStack(spacing: 0) {
                    PopoverActionView(popoverAction: .changeName) {
                        
                    }
                    divider
                    PopoverActionView(popoverAction: .addParentFolder) {
                        
                    }
                    divider
                    PopoverActionView(popoverAction: .addSubFolder) {
                        
                    }
                    divider
                    PopoverActionView(popoverAction: .delete) {
                        
                    }
                }
            }
    }
    
    private var divider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(.primary2)
    }
}



private struct PopoverActionView: View {
    let popoverAction: PopoverAction
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Text(popoverAction.label)
                .reazyFont(.h3)
                .foregroundStyle( popoverAction == .delete ? .pen1 : .gray800 )
            Spacer()
            popoverAction.image
        }
        .frame(height: 42)
        .padding(.leading, 17)
        .padding(.trailing, 14)
    }
    
    
    enum PopoverAction {
        case changeName
        case addParentFolder
        case addSubFolder
        case delete
        
        var label: String {
            switch self {
            case .changeName:
                "이름 및 색상 변경"
            case .addParentFolder:
                "상위 폴더 추가"
            case .addSubFolder:
                "하위 폴더 추가"
            case .delete:
                "삭제"
            }
        }
        
        var image: some View {
            switch self {
            case .changeName:
                Image(.editpencil)
            case .addParentFolder, .addSubFolder:
                Image(.newfolder)
                    .renderingMode(.template)
            case .delete:
                Image(.trash)
            }
        }
    }
}


#Preview {
    HomeFolderPopoverView()
        .background(.red)
}
