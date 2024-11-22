//
//  MoveFolderView.swift
//  Reazy
//
//  Created by 유지수 on 11/20/24.
//

import SwiftUI

struct MoveFolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @State private var expandedFolders: Set<UUID> = []
    @State private var isTopLevelExpanded: Bool = true
    
    @Binding var createMovingFolder: Bool
    @Binding var isMovingFolder: Bool
    
    let items: [FileSystemItem] // 이동하고자 하는 Item 배열
    @Binding var selectedID: UUID? // Item의 이동 목적지 ID
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button(action: {
                        self.isMovingFolder.toggle()
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
                            switch item {
                            case .paper(let paperInfo):
                                homeViewModel.updatePaperLocation(at: paperInfo.id, folderID: selectedID)
                            case .folder(let folder):
                                homeViewModel.updateFolderLocation(at: folder.id, folderID: selectedID)
                            }
                        }
                        self.isMovingFolder.toggle()
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
                    FolderCell(
                        folder: topLevelFolder,
                        level: 0,
                        expandedFolders: $expandedFolders,
                        isTopLevel: true,  // <전체> 폴더
                        childFolders: childFolders(of:),
                        toggleExpansion: toggleExpansion,
                        hasChildren: hasChildren,
                        isTopLevelExpanded: $isTopLevelExpanded,
                        selectedID: $selectedID
                    )
                }
            }
        }
        .background(Color(hex: "F7F7FC"))
    }
    
    // 존재하지 않는 <전체> 임의 폴더 생성
    private var topLevelFolder: Folder {
        Folder(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            title: "전체",
            color: ".primary1",
            parentFolderID: nil
        )
    }
    
    private func childFolders(of folderID: UUID?) -> [Folder] {
        let excludedFolderIDs = items.compactMap { item in
            if case .folder(let folder) = item {
                return folder.id
            }
            return nil
        }
        
        if folderID == topLevelFolder.id {
            return homeViewModel.folders.filter { $0.parentFolderID == nil && !excludedFolderIDs.contains($0.id) }
        } else {
            return homeViewModel.folders.filter { $0.parentFolderID == folderID && !excludedFolderIDs.contains($0.id) }
        }
    }
    
    private func hasChildren(folder: Folder) -> Bool {
        !childFolders(of: folder.id).isEmpty
    }
    
    private func toggleExpansion(folder: Folder) {
        if expandedFolders.contains(folder.id) {
            expandedFolders.remove(folder.id)
        } else {
            expandedFolders.insert(folder.id)
        }
    }
}

struct FolderCell: View {
    let folder: Folder
    let level: Int
    @Binding var expandedFolders: Set<UUID>
    let isTopLevel: Bool
    let childFolders: (UUID) -> [Folder]
    let toggleExpansion: (Folder) -> Void
    let hasChildren: (Folder) -> Bool
    @Binding var isTopLevelExpanded: Bool
    
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 7)
                    .frame(width: 29, height: 29)
                    .foregroundStyle(level == 0 ? .primary1 : FolderColors.color(for: folder.color))
                    .overlay(
                        Image("folder")
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
                        
                        if isTopLevel {
                            Button(action: {
                                withAnimation {
                                    self.isTopLevelExpanded.toggle()
                                }
                            }) {
                                Image(systemName: isTopLevelExpanded ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray600)
                                    .padding(.trailing, 20)
                            }
                        } else if hasChildren(folder) {
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
            
            if (isTopLevel && isTopLevelExpanded) || expandedFolders.contains(folder.id) {
                ForEach(childFolders(folder.id), id: \.id) { subFolder in
                    FolderCell(
                        folder: subFolder,
                        level: level + 1,
                        expandedFolders: $expandedFolders,
                        isTopLevel: false,
                        childFolders: childFolders,
                        toggleExpansion: toggleExpansion,
                        hasChildren: hasChildren,
                        isTopLevelExpanded: $isTopLevelExpanded,
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
    MoveFolderView(createMovingFolder: .constant(false), isMovingFolder: .constant(false), items: [], selectedID: .constant(UUID()))
}
