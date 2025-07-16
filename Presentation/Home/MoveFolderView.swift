//
//  MoveFolderView.swift
//  Reazy
//
//  Created by 유지수 on 11/20/24.
//

import SwiftUI

struct MoveFolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
//    @State private var expandedFolders: Set<UUID> = []
    
    @Binding var createMovingFolder: Bool
    let items: [PaperInfo]
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button(action: {
                        homeViewModel.isMovingFolder.toggle()
                    }) {
                        Text("취소")
                            .reazyFont(.text1)
                            .foregroundStyle(.primary1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.createMovingFolder.toggle()
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
                            homeViewModel.updatePaperLocation(at: item.id, folderID: selectedID)
                        }
                        homeViewModel.isMovingFolder = false
                    }) {
                        Text("이동")
                            .reazyFont(.text1)
                            .foregroundStyle(selectedID == nil ? .gray550 : .primary1)
                    }
                    .disabled(selectedID == nil)
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
                        FolderCell(
                            folder: folder,
                            level: 0,
                            expandedFolders: $homeViewModel.expandedMoveFolders,
                            childFolders: homeViewModel.childFolders(of:),
                            toggleExpansion: homeViewModel.toggleExpansion,
                            hasChildren: homeViewModel.hasChildren,
                            selectedID: $selectedID
                        )
                    }
                }
            }
        }
        .background(Color(hex: "F7F7FC"))
        .onAppear {
            if items.count == 1, let firstItem = items.first {
                selectedID = firstItem.folderID
                
                DispatchQueue.main.async {
                    if let selectedID = selectedID {
                        homeViewModel.expandOnlyParentFolders(of: selectedID)
                    }
                }
            }
        }
        .onChange(of: homeViewModel.newFolderID) { _ , newFolderID in
            selectedID = newFolderID
        }
        .onChange(of: homeViewModel.newFolderParentID) { _ , parentID in
            if let parentID = parentID {
                homeViewModel.expandedMoveFolders.insert(parentID)
            }
        }
    }
    
//    private var rootFolders: [Folder] {
//        homeViewModel.folders.filter { $0.parentFolderID == nil }
//    }
    
//    private func childFolders(of folderID: UUID?) -> [Folder] {
//        homeViewModel.folders.filter { $0.parentFolderID == folderID }
//    }
    
//    private func hasChildren(folder: Folder) -> Bool {
//        !childFolders(of: folder.id).isEmpty
//    }
    
//    private func toggleExpansion(folder: Folder) {
//        if homeViewModel.expandedMoveFolders.contains(folder.id) {
//            homeViewModel.expandedMoveFolders.remove(folder.id)
//        } else {
//            homeViewModel.expandedMoveFolders.insert(folder.id)
//        }
//    }
    
//    private func expandOnlyParentFolders(of folderID: UUID) {
//        if let parentID = homeViewModel.getParentFolderID(for: folderID) {
//            homeViewModel.expandedMoveFolders.insert(parentID)
//            expandOnlyParentFolders(of: parentID)
//        }
//    }
}

struct FolderCell: View {
    let folder: Folder
    let level: Int
    @Binding var expandedFolders: Set<UUID>
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
                                Image(systemName: expandedFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
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
            
            if expandedFolders.contains(folder.id) {
                ForEach(childFolders(folder.id), id: \.id) { subFolder in
                    FolderCell(
                        folder: subFolder,
                        level: level + 1,
                        expandedFolders: $expandedFolders,
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
    MoveFolderView(createMovingFolder: .constant(false), items: [], selectedID: .constant(UUID()))
}
