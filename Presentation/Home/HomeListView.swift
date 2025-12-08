//
//  HomeListView.swift
//  Reazy
//
//  Created by 유지수 on 1/27/25.
//

import SwiftUI

struct HomeListView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
  
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                categoryButton(image: "emptydoc", selectedImage: "document", title: String(localized: "전체"), status: .main)
                categoryButton(image: "star", selectedImage: "starfill", title: String(localized: "즐겨찾기"), status: .favorite)
                categoryButton(icon: "tag", selectedIcon: "tag.fill", title: String(localized: "태그"), status: .tag)
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
                        if homeViewModel.depth(of: homeViewModel.currentFolder?.id) < 4 {
                            homeViewModel.folderCreationPosition = .intoCurrent
                            homeViewModel.homeViewAction = .creatingFolder
                        } else {
                            homeViewModel.homeViewAction = .folderDepthAlert
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
                        ForEach(homeViewModel.rootFolders, id: \.id) { folder in
                            FolderListCell(
                                folder: folder,
                                level: 0,
                                childFolders: homeViewModel.childFolders(of:),
                                toggleExpansion: homeViewModel.toggleExpansionFolder(folder:),
                                hasChildren: homeViewModel.hasChildren(folder:),
                                didSelectFolder: { folderID in
                                    homeViewModel.categoryButtonTapped(.folder(folderID))
                                },
                                handleDrop: homeViewModel.handleDrop(to:droppedItem:),
                                onLongPressGesture: { folder, drag in
                                    if let drag = drag {
                                        homeViewModel.homeViewStatus = .folder(folder.id)
                                        homeViewModel.homeViewAction = .folderPopover(
                                            position: .init(
                                                x: 140,
                                                y: drag.location.y + 85
                                            )
                                        )
                                    }
                                }
                            )
                            .padding(.top, 10)
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
        status: HomeViewStatus
    ) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(homeViewModel.homeViewStatus == status ? .gray300 : .primary2)
            .frame(height: 43)
            .overlay {
                HStack(spacing: 0) {
                    if let icon = icon, let selectedIcon = selectedIcon {
                        Image(systemName: homeViewModel.homeViewStatus == status ? selectedIcon : icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(homeViewModel.homeViewStatus == status ? .primary1 : .gray700)
                            .padding(.trailing, 11)
                    } else if let image = image, let selectedImage = selectedImage {
                        Image(homeViewModel.homeViewStatus == status ? selectedImage : image)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(homeViewModel.homeViewStatus == status ? .primary1 : .gray700)
                            .padding(.trailing, 11)
                    }
                    
                    Text(title)
                        .reazyFont(homeViewModel.homeViewStatus == status ? .button1 : .text1)
                        .foregroundStyle(homeViewModel.homeViewStatus == status ? .primary1 : .gray700)
                    
                    Spacer()
                }
                .padding(.leading, 20)
            }
            .onTapGesture {
                homeViewModel.categoryButtonTapped(status)
            }
            .padding(.bottom, 3)
    }
}


private struct FolderListCell: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    let folder: Folder
    let level: Int
    let childFolders: (UUID) -> [Folder]
    let toggleExpansion: (Folder) -> Void
    let hasChildren: (Folder) -> Bool
    var didSelectFolder: (UUID) -> Void
    var handleDrop: (UUID, PaperInfo) -> Void
    
    @State private var animationFolder: Folder?
    var onLongPressGesture: (Folder, DragGesture.Value?) -> Void
    @GestureState private var highlight = false
    
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
                                Image(systemName: homeViewModel.expandedFolders.contains(folder.id) ? "chevron.down" : "chevron.right")
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
            .background(homeViewModel.homeViewStatus.currentFolderID == folder.id ? .gray300 : .clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .global))
                    .updating($highlight) { currentState, gestureState, transaction in
                        if case .second(true, _) = currentState {
                            self.animationFolder = folder
                            transaction.animation = .easeIn(duration: 1)
                            gestureState = true
                        }
                    }
                    .onEnded { value in
                        switch value {
                        case .second(true, let drag):
                            onLongPressGesture(folder, drag)
                        default:
                            break
                        }
                    }
            )
            .onMouse(
                onTap: {
                    didSelectFolder(folder.id)
                },
                onRightClick: { globalPoint in
                    homeViewModel.homeViewStatus = .folder(folder.id)
                    homeViewModel.homeViewAction = .folderPopover(
                        position: .init(x: 140, y: globalPoint.y + 85)
                    )
                }
            )
            .scaleEffect((animationFolder == folder && highlight) ? 1.2 : 1)
            .dropDestination(for: PaperInfo.self) { droppedItems, location in
                        if let droppedItem = droppedItems.first {
                    handleDrop(folder.id, droppedItem)
                    return true
                }
                return false
            }
            
            if homeViewModel.expandedFolders.contains(folder.id) {
                ForEach(childFolders(folder.id), id: \.id) { subFolder in
                    FolderListCell(
                        folder: subFolder,
                        level: level + 1,
                        childFolders: childFolders,
                        toggleExpansion: toggleExpansion,
                        hasChildren: hasChildren,
                        didSelectFolder: didSelectFolder,
                        handleDrop: handleDrop,
                        onLongPressGesture: onLongPressGesture
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
