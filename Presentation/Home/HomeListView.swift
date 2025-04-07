//
//  HomeListView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

struct HomeListView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @State private var expandedFolders: Set<UUID> = []
    
    @State private var selectedCategory: CategorySelection = .main
    
    @State private var animationFolder: Folder?
    @GestureState private var highlight = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                categoryButton(image: "emptydoc", selectedImage: "document", title: "전체", category: .main)
                categoryButton(image: "star", selectedImage: "starfill", title: "즐겨찾기", category: .favorite)
                categoryButton(icon: "tag", selectedIcon: "tag.fill", title: "태그", category: .tag)
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
                        if homeViewModel.depth(of: homeViewModel.currentFolder) < 4 {
                            homeViewModel.folderCreationPosition = .intoCurrent
                            homeViewModel.createFolder = true
                        } else {
                            homeViewModel.showFolderDepthAlert = true
                        }
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
                .padding(.leading, 20)
                .padding(.trailing, 6)
                
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
                                selectedFolderID: $homeViewModel.selectedFolderID,
                                didSelectFolder: { folderID in
                                    selectedCategory = .folder(folderID)
                                    homeViewModel.selectCategory(.folder(folderID))
                                },
                                handleDrop: handleDrop(to:droppedItem:)
                            )
                            .padding(.top, 10)
                            .gesture(LongPressGesture(minimumDuration: 0.5)
                                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                                .updating($highlight) { currentState, gestureState, transaction in
                                    self.animationFolder = folder
                                    transaction.animation = .easeIn(duration: 1)
                                    gestureState = true
                                }
                                .onEnded { value in
                                    switch value {
                                    case .second(true, let drag):
                                        if let drag = drag {
                                            homeViewModel.viewStatus = .folderPopover(
                                                .init(x: 40 + 100, y: drag.location.y + 85)
                                            )
                                            homeViewModel.selectedFolderID = folder.id
                                        }
                                    default:
                                        break
                                    }
                                }
                            )
                            .scaleEffect((animationFolder == folder && highlight) ? 1.2 : 1)
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
            
            Spacer()
        }
        .padding(.top, 24)
        .background(.primary2)
    }
    
    private func categoryButton(
        icon: String? = nil,
        selectedIcon: String? = nil,
        image: String? = nil,
        selectedImage: String? = nil,
        title: String,
        category: CategorySelection
    ) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(selectedCategory == category ? Color(hex: "EFEFF8") : .primary2)
            .frame(height: 43)
            .overlay {
                HStack(spacing: 0) {
                    if let icon = icon, let selectedIcon = selectedIcon {
                        Image(systemName: selectedCategory == category ? selectedIcon : icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selectedCategory == category ? .primary1 : .gray700)
                            .padding(.trailing, 11)
                    } else if let image = image, let selectedImage = selectedImage {
                        Image(selectedCategory == category ? selectedImage : image)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(selectedCategory == category ? .primary1 : .gray700)
                            .padding(.trailing, 11)
                    }
                    
                    Text(title)
                        .reazyFont(selectedCategory == category ? .button1 : .text1)
                        .foregroundStyle(selectedCategory == category ? .primary1 : .gray700)
                    
                    Spacer()
                }
                .padding(.leading, 20)
            }
            .onTapGesture {
                selectedCategory = category
                homeViewModel.selectCategory(category)
            }
            .padding(.bottom, 3)
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
        withAnimation {
            if expandedFolders.contains(folder.id) {
                expandedFolders.remove(folder.id)
            } else {
                expandedFolders.insert(folder.id)
            }
        }
    }
    
    private func handleDrop(to folderId: UUID, droppedItem: PaperInfo) {
        DispatchQueue.main.async {
            homeViewModel.updatePaperLocation(at: droppedItem.id, folderID: folderId)
        }
    }
}


private struct FolderListCell: View {
    
    let folder: Folder
    let level: Int
    @Binding var expandedFolders: Set<UUID>
    let childFolders: (UUID) -> [Folder]
    let toggleExpansion: (Folder) -> Void
    let hasChildren: (Folder) -> Bool
    @Binding var selectedFolderID: UUID?
    var didSelectFolder: (UUID) -> Void
    var handleDrop: (UUID, PaperInfo) -> Void
    
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
                    .padding(.leading, 20)
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
                                toggleExpansion(folder)
                            }) {
                                Image(systemName: expandedFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.gray600)
                                    .padding(.trailing, 4)
                            }
                            .padding(.trailing, 10)
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
                didSelectFolder(folder.id)
            }
            .dropDestination(for: PaperInfo.self) { droppedItems, location in
                if let droppedItem = droppedItems.first {
                    handleDrop(folder.id, droppedItem)
                    return true
                }
                return false
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
                        selectedFolderID: $selectedFolderID,
                        didSelectFolder: didSelectFolder,
                        handleDrop: handleDrop
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 10)
                }
            } else {
                EmptyView()
            }
        }
    }
}


#Preview {
    HomeListView()
}
