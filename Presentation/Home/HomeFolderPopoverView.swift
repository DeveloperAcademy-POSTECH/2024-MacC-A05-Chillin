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
        RoundedRectangle(cornerRadius: 12)
            .frame(width: 200, height: 171)
            .foregroundStyle(.white)
            .overlay {
                VStack(spacing: 0) {
                    PopoverActionView(popoverAction: .changeName) {
                        homeViewModel.homeViewAction = .editingFolder
                    }
                    divider
                    PopoverActionView(popoverAction: .addParentFolder) {
                        if homeViewModel.totalDepthInBranch(for: homeViewModel.homeViewStatus.currentFolderID) < 4 {
                            homeViewModel.folderCreationPosition = .aboveCurrent
                            homeViewModel.homeViewAction = .creatingFolder
                        } else {
                            homeViewModel.homeViewAction = .folderDepthAlert
                        }
                    }
                    divider
                    PopoverActionView(popoverAction: .addSubFolder) {
                        if homeViewModel.totalDepthInBranch(for: homeViewModel.homeViewStatus.currentFolderID) < 4 {
                            homeViewModel.folderCreationPosition = .intoCurrent
                            homeViewModel.homeViewAction = .creatingFolder
                        } else {
                            homeViewModel.homeViewAction = .folderDepthAlert
                        }
                    }
                    divider
                    PopoverActionView(popoverAction: .delete) {
                        homeViewModel.homeViewAction = .deletingFolderAlert
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
        Button {
            action()
        } label: {
            HStack(spacing: 0) {
                Text(popoverAction.label)
                    .reazyFont(.h3)
                    .foregroundStyle( popoverAction == .delete ? .pen1 : .gray800 )
                    .multilineTextAlignment(.leading)
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
                String(localized: "이름 및 색상 변경")
            case .addParentFolder:
                String(localized: "상위 폴더 추가")
            case .addSubFolder:
                String(localized: "하위 폴더 추가")
            case .delete:
                String(localized: "삭제")
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
