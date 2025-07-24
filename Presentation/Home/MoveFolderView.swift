//
//  MoveFolderView.swift
//  Reazy
//
//  Created by 유지수 on 11/20/24.
//

import SwiftUI

struct MoveFolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var id: UUID?
    let items: [PaperInfo]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button(action: {
                        homeViewModel.homeViewAction = .none
                    }) {
                        Text("취소")
                            .reazyFont(.text1)
                            .foregroundStyle(.primary1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if homeViewModel.depth(of: self.id) < 4 {
                            homeViewModel.homeViewAction = .creatingMovingFolder(id)
                        } else {
                            homeViewModel.homeViewAction = .folderDepthAlert
                        }
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18)
                            .foregroundStyle(.primary1)
                    }
                    .padding(.trailing, 26)
                    
                    Button(action: {
                        items.forEach { item in
                            homeViewModel.updatePaperLocation(at: item.id, folderID: id)
                        }
                        homeViewModel.homeViewAction = .none
                    }) {
                        Text("이동")
                            .reazyFont(.text1)
                            .foregroundStyle(id == nil ? .gray550 : .primary1)
                    }
                    .disabled(id == nil)
                }
                .padding(.horizontal, 20)
                
                HStack(spacing: 0) {
                    Spacer()
                    
                    Text("위치 선택")
                        .reazyFont(.button1)
                        .foregroundStyle(Color(hex: "3C3D4B"))
                    
                    Spacer()
                }
            }
            .padding(.vertical, 14)
            
            Rectangle()
                .foregroundStyle(Color(hex: "D9DBE9"))
                .frame(height: 1)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(homeViewModel.rootFolders, id: \.id) { folder in
                        FolderMoveCell(
                            folder: folder,
                            level: 0,
                            expandedMoveFolders: $homeViewModel.expandedMoveFolders,
                            childFolders: homeViewModel.childFolders(of:),
                            toggleExpansion: homeViewModel.toggleExpansionMoveFolders(folder:),
                            hasChildren: homeViewModel.hasChildren,
                            selectedID: $id
                        )
                    }
                }
            }
        }
        .background(Color(hex: "F7F7FC"))
        .onAppear {
            if let action = homeViewModel.previousAction,
               case let .creatingMovingFolder(id) = action,
               let id = id
            {
                self.id = id
                DispatchQueue.main.async {
                    homeViewModel.expandOnlyParentFolders(of: id)
                }
                return
            }
            
            
            if items.count == 1, let firstItem = items.first {
                id = firstItem.folderID
                
                DispatchQueue.main.async {
                    if let id = id {
                        homeViewModel.expandOnlyParentFolders(of: id)
                    }
                }
            }
        }
        .onChange(of: homeViewModel.newFolderID) { _ , newFolderID in
            id = newFolderID
        }
        .onChange(of: homeViewModel.newFolderParentID) { _ , parentID in
            if let parentID = parentID {
                homeViewModel.expandedMoveFolders.insert(parentID)
            }
        }
    }
}

private struct FolderMoveCell: View {
    let folder: Folder
    let level: Int
    @Binding var expandedMoveFolders: Set<UUID>
    let childFolders: (UUID) -> [Folder]
    let toggleExpansion: (Folder) -> Void
    let hasChildren: (Folder) -> Bool
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 7)
                    .frame(width: 29, height: 29)
                    .foregroundStyle(FolderColors.color(for: folder.color))
                    .overlay(
                        Image(.folder)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 13)
                    )
                    .padding(.trailing, 12)
                    .padding(.vertical, 12)
                
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Text(folder.title)
                            .reazyFont(.button3)
                            .foregroundStyle(.gray900)
                        
                        Spacer()
                        
                        if hasChildren(folder) {
                            Button(action: {
                                withAnimation {
                                    toggleExpansion(folder)
                                }
                            }) {
                                Image(systemName: expandedMoveFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray600)
                                    .padding(.trailing, 20)
                            }
                        }
                    }
                    
                    Spacer()
                    Rectangle()
                        .frame(height: 0.77)
                        .foregroundStyle(.primary3)
                }
            }
            .padding(.leading, CGFloat(20 + (level * 21)))
            .background(selectedID == folder.id ? .primary2 : .clear)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            if expandedMoveFolders.contains(folder.id) {
                ForEach(childFolders(folder.id), id: \.id) { subFolder in
                    FolderMoveCell(
                        folder: subFolder,
                        level: level + 1,
                        expandedMoveFolders: $expandedMoveFolders,
                        childFolders: childFolders,
                        toggleExpansion: toggleExpansion,
                        hasChildren: hasChildren,
                        selectedID: $selectedID
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func onTap() {
        if selectedID != folder.id {
            selectedID = folder.id
        }
    }
}

#Preview {
    MoveFolderView(items: [])
}
