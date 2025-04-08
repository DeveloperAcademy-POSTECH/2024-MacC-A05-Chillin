//
//  HomeFolderPopoverView.swift
//  Reazy
//
//  Created by 문인범 on 3/26/25.
//

import SwiftUI


struct HomeFolderPopoverView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            PopoverActionView(popoverAction: .changeName) {
                homeViewModel.viewStatus = .normal
                homeViewModel.isEditingFolder = true
            }
            divider
            PopoverActionView(popoverAction: .addParentFolder) {
                homeViewModel.viewStatus = .normal
                homeViewModel.folderCreationPosition = .aboveCurrent
                homeViewModel.createFolder = true
            }
            divider
            PopoverActionView(popoverAction: .addSubFolder) {
                homeViewModel.viewStatus = .normal
                if homeViewModel.depth(of: homeViewModel.currentFolder) < 4 {
                    homeViewModel.folderCreationPosition = .intoCurrent
                    homeViewModel.createFolder = true
                } else {
                    homeViewModel.showFolderDepthAlert = true
                }
            }
            divider
            PopoverActionView(popoverAction: .delete) {
                homeViewModel.viewStatus = .normal
                homeViewModel.showDeleteAlert = true
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
        Button {
            action()
        } label: {
            HStack(spacing: 0) {
                Text(popoverAction.label)
                    .reazyFont(.h3)
                    .foregroundStyle( popoverAction == .delete ? .pen1 : .gray800 )
                Spacer()
                popoverAction.image
            }
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
