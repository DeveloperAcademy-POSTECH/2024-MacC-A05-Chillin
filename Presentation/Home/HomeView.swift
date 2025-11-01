//
//  HomeView.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI



struct HomeView: View {
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    
    @StateObject private var homeSearchViewModel: HomeSearchViewModel = .init(
        useCase: DefaultHomeSearchUseCase(
            paperDataRepository: PaperDataRepositoryImpl(),
            tagDataRepository: TagDataRepositoryImpl()
        )
    )
    
    @StateObject private var tagViewModel: TagViewModel = .init(
        tagViewUseCase: DefaultTagViewUseCase(
            tagRepository: TagDataRepositoryImpl(),
            paperDataRepository: PaperDataRepositoryImpl()
        )
    )
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(.point1)
                    
                    HStack(spacing: 0) {
                        Image(.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 62, height: 50)
                            .padding(.trailing, 36)
                        
                        Spacer()
                        
                        switch homeViewModel.homeViewStatus {
                        case .search:
                            SearchMenuView()
                                .environmentObject(homeSearchViewModel)
                        case .edit:
                            EditMenuView()
                        default:
                            MainMenuView()
                        }
                    }
                    .padding(.top, 46)
                    .padding([.leading, .bottom], 28)
                }
                .frame(height: 80)
                
                GeometryReader { geometry in
                    switch homeViewModel.homeViewStatus {
                    case .search:
                        HomeSearchView()
                            .environmentObject(homeSearchViewModel)
                    default:
                        HStack(spacing: 0) {
                            SidePanelView(geometry: geometry)
                            
                            ContentPanelView()
                                .environmentObject(homeSearchViewModel)
                        }
                    }
                }
            }
            .blur(radius: homeViewModel.homeViewAction.blurredConstant)
            
            Color.black
                .opacity(homeViewModel.homeViewAction.backgroundOpacity)
                .ignoresSafeArea(edges: .bottom)
                .onTapGesture {
                    // MARK: 배결 터치시 이전 화면 돌아가기 필요 시 넣기
                }
            
            if homeViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.primary1)
            }
        }
        .background(Color(hex: "F7F7FB"))
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut, value: homeViewModel.homeViewAction)
        .alert(isPresented: $tagViewModel.isTagDuplicate) {
            Alert(
                title: Text("이미 추가된 태그입니다.\n새로운 태그를 입력해 주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
        .overlay {
            switch homeViewModel.homeViewAction {
            case .setting:
                SettingView()
            case .creatingFolder, .editingFolder:
                FolderView(
                    folder: homeViewModel.folders.first { $0.id == homeViewModel.homeViewStatus.currentFolderID },
                    cancelAction: {
                        if let action = homeViewModel.previousAction, action == .movingFolder {
                            homeViewModel.homeViewAction = action
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    },
                    completeAction: { color, title, folder in
                        let text = title.isEmpty ? String(localized: "새 폴더") : title

                        if case .creatingFolder = homeViewModel.homeViewAction {
                            if homeViewModel.isAtRoot {
                                homeViewModel.createSubfolder(in: nil, title: text, color: color.rawValue)
                            } else {
                                switch homeViewModel.folderCreationPosition {
                                case .intoCurrent:
                                    homeViewModel.createSubfolderInSelectedFolder(title: text, color: color.rawValue)
                                case .aboveCurrent:
                                    homeViewModel.createFolderAboveSelectedFolder(title: text, color: color.rawValue)
                                }
                            }
                        } else {
                            if let folder = folder {
                                homeViewModel.updateFolderInfo(at: folder.id, title: text, color: color.rawValue)
                            }
                        }
                        
                        if let action = homeViewModel.previousAction, action == .movingFolder {
                            homeViewModel.homeViewAction = action
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    }
                )
            case let .creatingMovingFolder(id):
                FolderView(
                    folder: homeViewModel.folders.first { $0.id == id },
                    cancelAction: {
                        if let action = homeViewModel.previousAction, action == .movingFolder {
                            homeViewModel.homeViewAction = action
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    },
                    completeAction: { color, title, folder in
                        let text = title.isEmpty ? String(localized: "새 폴더") : title
                        
                        if let folder = folder {
                            homeViewModel.createSubfolder(in: folder.id, title: text, color: color.rawValue)
                        } else {
                            homeViewModel.createSubfolder(in: nil, title: text, color: color.rawValue)
                        }
                        
                        if let action = homeViewModel.previousAction, action == .movingFolder {
                            homeViewModel.homeViewAction = action
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    }
                )
            case .movingFolder:
                MoveFolderView(
                    items: homeViewModel.itemsToMove,
                    cancelAction: {
                        homeViewModel.homeViewAction = .none
                    },
                    createFolderAction: { folderId in
                        if homeViewModel.depth(of: folderId) < 4 {
                            homeViewModel.homeViewAction = .creatingMovingFolder(folderId)
                        } else {
                            homeViewModel.homeViewAction = .folderDepthAlert
                        }
                    },
                    moveAction: { folderId in
                        homeViewModel.itemsToMove.forEach { item in
                            homeViewModel.updatePaperLocation(at: item.id, folderID: folderId)
                        }
                        homeViewModel.homeViewAction = .none
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 740, height: 550)
            case .creatingTag:
                CreateTagView()
                    .environmentObject(tagViewModel)
            case let .addTagToPaper(paperInfo):
                TagControlView(paperInfo: paperInfo) {
                    homeViewModel.homeViewAction = .none
                } completeAction: {
                    homeViewModel.homeViewAction = .none
                }
                .onDisappear {
                    homeViewModel.fetchPaperList()
                    tagViewModel.fetchFilteredPaperList()
                }
            case let .editingPaperTitle(paperInfo):
                RenamePaperTitleView(paperInfo: paperInfo) {
                    homeViewModel.homeViewAction = .none
                } completeAction: { text in
                    homeViewModel.updateTitle(at: paperInfo.id, title: text) {
                        if !$0 {
                            homeViewModel.homeViewAction = .duplicatedTitleAlert
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    }
                }
                .ignoresSafeArea(edges: .top)
            case let .folderPopover(position):
                HomeFolderPopoverView()
                    .environmentObject(homeViewModel)
                    .position(.init(
                        x: position.x,
                        y: UIScreen.main.bounds.height - position.y < 171 ? position.y - 200 : position.y
                    ))
            case .duplicatedTitleAlert:
                CustomAlert(
                    type: .confirm,
                    mainText: "같은 제목의 논문이 이미 존재합니다",
                    message: "다른 제목을 입력해주세요",
                    width: 350,
                    height: 176,
                    cancelAction: {
                        homeViewModel.homeViewAction = .none
                    },
                    confirmAction: {}
                )
            case let .deletingTagAlert(name, id):
                CustomAlert(
                    mainText: "\"\(name)\"\n태그를 삭제하시겠습니까?",
                    message: "해당 태그가 달린 모든 논문에서도 삭제됩니다.", width: 350, height: 173,
                    cancelAction: {
                        homeViewModel.homeViewAction = .none
                    },
                    confirmAction: {
                        tagViewModel.deleteTagButtonTapped(id: id)
                        homeViewModel.homeViewAction = .none
                    }
                )
            case .deletingFolderAlert:
                CustomAlert(
                    mainText: "폴더를 삭제하시겠습니까?",
                    message: "폴더 안에 포함된 논문도 함께 삭제됩니다.",
                    width: 364, height: 163,
                    cancelAction: { homeViewModel.homeViewAction = .none },
                    confirmAction: {
                        if let id = homeViewModel.homeViewStatus.currentFolderID {
                            homeViewModel.deleteFolder(at: id)
                        }
                    }
                )
            case .folderDepthAlert:
                CustomAlert(
                    type: .confirm,
                    mainText: "Reazy는 하위 폴더를\n4개까지 제공합니다.",
                    width: 340, height: 163,
                    cancelAction: {
                        if let action = homeViewModel.previousAction,
                           case .movingFolder = action {
                            homeViewModel.homeViewAction = .movingFolder
                        } else {
                            homeViewModel.homeViewAction = .none
                        }
                    }
                )
            case .none, .deletingPaperAlert, .deletingMultiPapersAlert:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private func SidePanelView(geometry: GeometryProxy) -> some View {
        if homeViewModel.homeViewStatus != .edit {
            HomeListView()
                .frame(width: geometry.size.width / 4)
        }
    }
    
    @ViewBuilder
    private func ContentPanelView() -> some View {
        switch homeViewModel.homeViewStatus {
        case .tag:
            TagView()
                .environmentObject(tagViewModel)
        default:
            PaperListView()
                .onAppear {
                    homeViewModel.fetchPaperList()
                }
        }
    }
}

#Preview {
    HomeView()
}


/// 기본 화면 버튼 뷰
private struct MainMenuView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var isFileImporterPresented: Bool = false
    @State private var errorAlert: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    homeViewModel.homeViewStatus = .search
                }
            }) {
                Image(.search)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    homeViewModel.homeViewStatus = .edit
                }
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 17.68))
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    homeViewModel.homeViewAction = .setting
                }
            }) {
                Image(.setting)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                self.isFileImporterPresented.toggle()
                self.homeViewModel.isLoading = true
            }) {
                Text("가져오기")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false,
            onCompletion: importPDFToDevice)
        .onChange(of: isFileImporterPresented) { _, newValue in
            if !newValue {
                self.homeViewModel.isLoading = false
            }
        }
    }
    
    private func importPDFToDevice(result: Result<[Foundation.URL], any Error>) {
        switch result {
        case .success(let url):
            if let newPaperID = homeViewModel.uploadPDF(url: url) {
                homeViewModel.selectedItemID = newPaperID
            } else {
                print("Duplicated File Name")
            }
        case .failure(let error):
            print(String(describing: error))
        }
    }
}

/// 검색 화면 버튼 뷰
private struct SearchMenuView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    // 검색 버튼 클릭 시 검색창 자동 포커싱
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            SearchBar()
                .frame(width: 400)
                .focused($isSearchFieldFocused)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    homeViewModel.homeViewStatus = .main
                }
                isSearchFieldFocused = false
            }, label: {
                Text("취소")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
        }
        .onAppear {
            isSearchFieldFocused = true
        }
    }
}

/// 수정 화면 버튼 뷰
private struct EditMenuView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                homeViewModel.homeViewAction = .movingFolder
            }, label: {
                Image(.move)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(homeViewModel.selectedItems.isEmpty ? .gray550 : .gray100)
            })
            .disabled(homeViewModel.selectedItems.isEmpty)
            .padding(.trailing, 28)
            
            Button(action: {
                homeViewModel.homeViewAction = .deletingMultiPapersAlert
            }, label: {
                Image(.trash)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(homeViewModel.selectedItems.isEmpty ? .gray550 : .gray100)
            })
            .disabled(homeViewModel.selectedItems.isEmpty)
            .padding(.trailing, 28)
            
            Button(action: {
                homeViewModel.homeViewStatus = .main
                homeViewModel.selectedItems.removeAll()
            }, label: {
                Text("완료")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
        }
        .alert(
            "정말 삭제하시겠습니까?",
            isPresented: homeViewModel.homeViewAction.isDeleteMultiPapersAlertPresented,
            presenting: homeViewModel.selectedItems
        ) { itemList in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                let items: [PaperInfo] = itemList.compactMap { id in
                    homeViewModel.filteredLists.first(where: { $0.id == id })
                }
                
                homeViewModel.deleteFiles(items)
                homeViewModel.selectedItems.removeAll()
            }
        } message: { itemList in
            Text("삭제된 파일은 복구할 수 없습니다.")
        }
    }
}


/// 폴더 생성 뷰
struct FolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var selectedColors: FolderColors = .folder1
    @State private var text: String = ""
    
    let folder: Folder?
    
    let cancelAction: () -> Void
    let completeAction: (FolderColors, String, Folder?) -> Void
        
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(action: {
                        cancelAction()
                        
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        completeAction(selectedColors, text, folder)
                    }) {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray100, lineWidth: 1)
                            .frame(width: 68, height: 36)
                            .overlay {
                                Text("완료")
                                    .reazyFont(.button1)
                                    .foregroundStyle(.gray100)
                            }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 49)
                    .frame(width: 206, height: 206)
                    .foregroundStyle(selectedColors.color)
                    .overlay(
                        Image(.folder)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 105)
                    )
                    .padding(.trailing, 54)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(FolderColors.allCases, id: \.self) { color in
                            FolderColorButton(
                                button: $selectedColors,
                                selectedButton: color,
                                action: {
                                    selectedColors = color
                                }
                            )
                            .padding(.trailing, color == .folder7 ? 0 : 20)
                        }
                    }
                    .padding(.bottom, 24)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .frame(width: 400, height: 52)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray400)
                            .frame(width: 400, height: 52)
                    }
                    .frame(width: 400, height: 52)
                    .overlay(alignment: .leading) {
                        TextField("폴더 제목을 입력해주세요.", text: $text, axis: .horizontal)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .font(.custom(ReazyFontType.pretendardMediumFont, size: 16))
                            .foregroundStyle(.gray800)
                    }
                    .overlay(alignment: .trailing) {
                        if !self.text.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                                .padding(.trailing, 10)
                                .onTapGesture {
                                    text = ""
                                }
                        }
                    }
                    .padding(.bottom, 16)
                    
                    Text("폴더 제목을 입력해 주세요")
                        .reazyFont(.button1)
                        .foregroundStyle(.comment)
                }
            }
        }
        .onAppear {
            if homeViewModel.homeViewAction == .editingFolder, let folder = folder {
                text = folder.title
                selectedColors = FolderColors(rawValue: folder.color) ?? .folder1
            }
        }
    }
}

/// 태그 생성 뷰
private struct CreateTagView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var tagViewModel: TagViewModel
    @State private var text: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        homeViewModel.homeViewAction = .none
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(.gray100)
                    .padding(28)
                    
                    Spacer()
                    
                    Button {
                        if text.isEmpty {
                            text = "새 태그"
                            homeViewModel.homeViewAction = .none
                            return
                        }
                        if let _ = tagViewModel.tags.filter({$0.name == text}).first {
                            homeViewModel.homeViewAction = .none
                            tagViewModel.isTagDuplicate = true
                        } else {
                            tagViewModel.createTag(name: text)
                            homeViewModel.homeViewAction = .none
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.gray100, lineWidth: 1)
                            .frame(width: 68, height: 36)
                            .overlay {
                                Text("완료")
                                    .reazyFont(.button1)
                                    .foregroundStyle(.gray100)
                            }
                    }
                    .padding(28)
                }
                Spacer()
            }
            HStack(spacing: 0) {
                Image(systemName: "tag")
                    .font(.system(size: 180))
                    .padding(.trailing, 70)
                    .foregroundStyle(.primary3)
                
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .frame(width: 400, height: 52)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray400)
                            .frame(width: 400, height: 52)
                    }
                    .overlay {
                        TextField("새로운 태그", text: $text, axis: .horizontal)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .font(.custom(ReazyFontType.pretendardMediumFont, size: 16))
                            .foregroundStyle(.gray800)
                    }
                    Text("새로운 태그를 입력해주세요")
                        .foregroundStyle(.comment)
                        .reazyFont(.button1)
                        .padding(.top, 16)
                }
            }
        }
        .animation(.easeInOut, value: tagViewModel.isTagDuplicate)
        .onChange(of: text) { _, newValue in
            if newValue.count > 30 {
                text = String(newValue.prefix(30))
            }
        }
    }
}
