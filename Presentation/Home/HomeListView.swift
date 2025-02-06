//
//  HomeListView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

struct HomeListView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @Binding var createFolder: Bool
    @Binding var selectedFolderID: UUID?
    @State private var expandedFolders: Set<UUID> = []
    
    @State private var isMainSelected: Bool = true
    @State private var isFavoriteSelected: Bool = false
    @State private var isTagSelected: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isMainSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(systemName: isMainSelected ? "text.page.fill" : "text.page")
                                .font(.system(size: 18))
                                .foregroundStyle(isMainSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("전체")
                                .reazyFont(isMainSelected ? .button1 : .text1)
                                .foregroundStyle(isMainSelected ? .primary1 : .gray700)
                            
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = true
                        self.isFavoriteSelected = false
                        self.isTagSelected = false
                        homeViewModel.isFavoriteSelected = false
                        homeViewModel.isTagSelected = false
                    }
                    .padding(.bottom, 3)
                
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isFavoriteSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(isFavoriteSelected ? "starfill" : "star")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(isFavoriteSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("즐겨찾기")
                                .reazyFont(isFavoriteSelected ? .button1 : .text1)
                                .foregroundStyle(isFavoriteSelected ? .primary1 : .gray700)
                            
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = false
                        self.isFavoriteSelected = true
                        self.isTagSelected = false
                        homeViewModel.isFavoriteSelected = true
                        homeViewModel.isTagSelected = false
                    }
                    .padding(.bottom, 3)
                
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(isTagSelected ? Color(hex: "EFEFF8") : .clear)
                    .frame(height: 43)
                    .overlay {
                        HStack(spacing: 0) {
                            Image(systemName: isTagSelected ? "tag.fill" : "tag")
                                .font(.system(size: 14))
                                .foregroundStyle(isTagSelected ? .primary1 : .gray700)
                                .padding(.trailing, 11)
                            
                            Text("태그")
                                .reazyFont(isTagSelected ? .button1 : .text1)
                                .foregroundStyle(isTagSelected ? .primary1 : .gray700)
                                
                            Spacer()
                        }
                        .padding(.leading, 20)
                    }
                    .onTapGesture {
                        self.isMainSelected = false
                        self.isFavoriteSelected = false
                        self.isTagSelected = true
                        homeViewModel.isFavoriteSelected = false
                        homeViewModel.isTagSelected = true
                    }
            }
            .padding(.leading, 10)
            .padding(.trailing, 12)
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray500)
                .padding(.top, 13)
                .padding(.bottom, 20)
                .padding(.leading, 30)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text("폴더")
                        .reazyFont(.text1)
                        .foregroundStyle(.gray700)
                    
                    Spacer()
                    
                    Button(action: {
                        createFolder.toggle()
                    }) {
                        Image("newfolder")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                            .foregroundStyle(.gray800)
                    }
                }
                .padding(.bottom, 14)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(rootFolders, id: \.id) { folder in
                            FolderListCell(
                                folder: folder,
                                level: 0,
                                expandedFolders: $expandedFolders,
                                childFolders: childFolders(of:),
                                toggleExpansion: toggleExpansion,
                                hasChildren: hasChildren(folder:),
                                selectedFolderID: $selectedFolderID
                            )
                            .padding(.top, 10)
                        }
                    }
                }
            }
            .padding(.leading, 30)
            .padding(.trailing, 16)
            
            Spacer()
        }
        .padding(.top, 24)
        .background(.primary2)
    }
    
    private var rootFolders: [Folder] {
        homeViewModel.folders.filter { $0.parentFolderID == nil }
    }
    
    private func childFolders(of folderID: UUID?) -> [Folder] {
        homeViewModel.folders.filter { $0.parentFolderID == folderID }
    }
    
    private func hasChildren(folder: Folder) -> Bool {
        !childFolders(of: folder.id).isEmpty
    }
    
    private func toggleExpansion(_ folder: Folder) {
        if expandedFolders.contains(folder.id) {
            expandedFolders.remove(folder.id)
        } else {
            expandedFolders.insert(folder.id)
        }
    }
}


struct FolderListCell: View {
    
    let folder: Folder
    let level: Int
    @Binding var expandedFolders: Set<UUID>
    let childFolders: (UUID) -> [Folder]
    let toggleExpansion: (Folder) -> Void
    let hasChildren: (Folder) -> Bool
    
    @Binding var selectedFolderID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 5.71)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(FolderColors.color(for: folder.color))
                    .overlay(
                        Image(.folder)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 11.43, height: 9.13)
                    )
                    .padding(.trailing, 10)
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        Text(folder.title)
                            .reazyFont(.text1)
                            .foregroundStyle(.gray700)
                        
                        Spacer()
                        
                        if hasChildren(folder) {
                            Button(action: {
                                withAnimation {
                                    toggleExpansion(folder)
                                }
                            }) {
                                Image(systemName: expandedFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.gray600)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.leading, CGFloat((level * 18)))
            .background(selectedFolderID == folder.id ? .gray300 : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            if expandedFolders.contains(folder.id) {
                ForEach(childFolders(folder.id), id: \.id) { subFolder in
                    FolderListCell(
                        folder: subFolder,
                        level: level + 1,
                        expandedFolders: $expandedFolders,
                        childFolders: childFolders,
                        toggleExpansion: toggleExpansion,
                        hasChildren: hasChildren,
                        selectedFolderID: $selectedFolderID
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func onTap() {
        if selectedFolderID != folder.id {
            selectedFolderID = folder.id
        }
    }
}


#Preview {
    HomeListView(
        createFolder: .constant(false),
        selectedFolderID: .constant(nil)
    )
}
