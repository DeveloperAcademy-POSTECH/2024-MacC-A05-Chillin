//
//  HomeView.swift
//  Reazy
//
//  Created by 문인범 on 10/14/24.
//

import SwiftUI

enum Options {
    case main
    case search
    case edit
}

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
                        
                        switch homeViewModel.selectedMenu {
                        case .main:
                            MainMenuView(
                                selectedMenu: $homeViewModel.selectedMenu,
                                selectedItemID: $homeViewModel.selectedItemID
                            )
                            
                        case .search:
                            SearchMenuView(selectedMenu: $homeViewModel.selectedMenu)
                                .environmentObject(homeSearchViewModel)
                            
                        case .edit:
                            EditMenuView(selectedMenu: $homeViewModel.selectedMenu)
                        }
                    }
                    .padding(.top, 46)
                    .padding([.leading, .bottom], 28)
                }
                .frame(height: 80)
                
                GeometryReader { geometry in
                    if homeViewModel.isSearching {
                        HomeSearchView()
                            .environmentObject(homeSearchViewModel)
                    } else {
                        HStack(spacing: 0) {
                            SidePanelView(geometry: geometry)
                            
                            ContentPanelView()
                                .environmentObject(homeSearchViewModel)
                        }
                    }
                }
            }
            .blur(radius: homeViewModel.isEditingTitle || homeViewModel.createFolder || homeViewModel.isEditingFolder || homeViewModel.createMovingFolder || tagViewModel.createTag || tagViewModel.isTagDuplicate ? 20 : 0)
            
            
            Color.black
                .opacity(
                    homeViewModel.isEditingTitle || homeViewModel.createFolder || homeViewModel.isEditingFolder
                    || homeViewModel.isMovingFolder || homeViewModel.isSettingMenu || tagViewModel.createTag
                    || tagViewModel.isTagDuplicate || tagViewModel.showDeleteAlert || homeViewModel.isDuplicatedTitleAlertPresented
                    || homeViewModel.showDeleteAlert
                    ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)
            
            Color.black
                .opacity(homeViewModel.viewStatus.isBlacked ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)
                .onTapGesture {
                    homeViewModel.viewStatus = .normal
                }
            
            if homeViewModel.createFolder || homeViewModel.isEditingFolder {
                FolderView(
                    createMovingFolder: $homeViewModel.createMovingFolder,
                    folder: homeViewModel.folders.first { $0.id == homeViewModel.selectedFolderID }
                )
            }
            
            // 폴더 이동 View
            if homeViewModel.isMovingFolder {
                MoveFolderView(
                    createMovingFolder: $homeViewModel.createMovingFolder,
                    items: homeViewModel.itemsToMove,
                    selectedID: $homeViewModel.moveToFolderID
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 740, height: 550)
                .blur(radius: homeViewModel.createMovingFolder ? 20 : 0)
            }
            
            Color.black
                .opacity(homeViewModel.createMovingFolder ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)
            
            // 폴더 이동 시 새 폴더 생성
            if homeViewModel.createMovingFolder {
                FolderView(
                    createMovingFolder: $homeViewModel.createMovingFolder,
                    folder: homeViewModel.newFolder
                )
            }
            
            // 세팅 메뉴 뷰
            if homeViewModel.isSettingMenu {
                SettingView()
            }
            
            if homeViewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.primary1)
            }
        }
        .background(Color(hex: "F7F7FB"))
        .ignoresSafeArea(edges: .top)
        .animation(.easeInOut, value: homeViewModel.isEditingTitle)
        .animation(.easeInOut, value: homeViewModel.isEditingFolder)
        .animation(.easeInOut, value: homeViewModel.isDuplicatedTitleAlertPresented)
        .alert(isPresented: $tagViewModel.isTagDuplicate) {
            Alert(
                title: Text("이미 추가된 태그입니다.\n새로운 태그를 입력해 주세요."),
                dismissButton: .default(Text("확인"))
            )
        }
        .blur(radius: ((homeViewModel.viewStatus.isBlurred) || (homeSearchViewModel.viewStatus != .normal) || homeViewModel.isDuplicatedTitleAlertPresented) ? 5 : 0)
        .overlay {
            if case let .search(paperInfo) = homeViewModel.viewStatus {
                RenamePaperTitleView(paperInfo: paperInfo) {
                    homeViewModel.viewStatus = .normal
                } completeAction: { text in
                    homeViewModel.updateTitle(at: paperInfo.id, title: text) {
                        if !$0 { homeViewModel.isDuplicatedTitleAlertPresented.toggle() }
                    }
                    homeViewModel.viewStatus = .normal
                }
                .ignoresSafeArea(edges: .top)
            }
            
            if case let .search(paperInfo) = homeSearchViewModel.viewStatus {
                RenamePaperTitleView(paperInfo: paperInfo) {
                    homeSearchViewModel.cancelButtonTappedInEditingTitle()
                } completeAction: { text in
                    homeSearchViewModel.completeButtonTappedInEditingTitle(title: text) {
                        if !$0 { homeViewModel.isDuplicatedTitleAlertPresented.toggle() }
                    }
                }
                .onDisappear {
                    homeSearchViewModel.searchPapers()
                }
            }
            // 태그 관리
            if case let .setTag(paperInfo) = homeSearchViewModel.viewStatus {
                TagControlView(paperInfo: paperInfo) {
                    homeSearchViewModel.viewStatus = .normal
                } completeAction: {
                    homeSearchViewModel.viewStatus = .normal
                }
                .onDisappear {
                    homeSearchViewModel.searchPapers()
                }
            }
            
            if case let .addTagToPaperInfo(paperInfo) = homeViewModel.viewStatus {
                TagControlView(paperInfo: paperInfo) {
                    homeViewModel.viewStatus = .normal
                } completeAction: {
                    homeViewModel.viewStatus = .normal
                }
                .onDisappear {
                    homeViewModel.fetchPaperList()
                    tagViewModel.fetchFilteredPaperList()
                }
            }
            
            // 태그 생성
            if tagViewModel.createTag {
                CreateTagView()
                    .environmentObject(tagViewModel)
            }
            
            if tagViewModel.showDeleteAlert {
                CustomAlert(mainText: "\"\(tagViewModel.getTagName())\"\n태그를 삭제하시겠습니까?",
                            message: "해당 태그가 달린 모든 논문에서도 삭제됩니다.", width: 350, height: 173,
                            cancelAction: { tagViewModel.showDeleteAlert = false },
                            confirmAction: tagViewModel.deleteTag)
            }
            
            if case .folderPopover = homeViewModel.viewStatus {
                if case let .folderPopover(position) = homeViewModel.viewStatus {
                    HomeFolderPopoverView()
                        .environmentObject(homeViewModel)
                        .position(.init(
                            x: position.x,
                            y: UIScreen.main.bounds.height - position.y < 171 ? position.y - 200 : position.y
                        ))
                }
            }
            
            if homeViewModel.showDeleteAlert {
                CustomAlert(
                    mainText: "폴더를 삭제하시겠습니까?",
                    message: "폴더 안에 포함된 논문도 함께 삭제됩니다.",
                    width: 364, height: 163,
                    cancelAction: { homeViewModel.showDeleteAlert = false },
                    confirmAction: {
                        if let id = homeViewModel.selectedFolderID {
                            homeViewModel.deleteFolder(at: id)
                        }
                    }
                )
            }
            
            if homeViewModel.showFolderDepthAlert {
                CustomAlert(
                    type: .confirm,
                    mainText: "Reazy는 하위 폴더를\n4개까지 제공합니다.",
                    width: 340, height: 163,
                    cancelAction: { homeViewModel.showFolderDepthAlert = false }
                )
            }
            
            if self.homeViewModel.isDuplicatedTitleAlertPresented {
                CustomAlert(
                    type: .confirm,
                    mainText: "같은 제목의 논문이 이미 존재합니다",
                    message: "다른 제목을 입력해주세요",
                    width: 350,
                    height: 176,
                    cancelAction: {
                        homeViewModel.isDuplicatedTitleAlertPresented.toggle()
                    },
                    confirmAction: {}
                )
            }
        }
    }
    
    @ViewBuilder
    private func SidePanelView(geometry: GeometryProxy) -> some View {
        if !homeViewModel.isEditing {
            HomeListView()
                .frame(width: geometry.size.width / 4)
        }
    }
    
    @ViewBuilder
    private func ContentPanelView() -> some View {
        if homeViewModel.isTagSelected {
            TagView()
                .environmentObject(tagViewModel)
        } else {
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
    
    @Binding var selectedMenu: Options
    
    @Binding var selectedItemID: UUID?
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedMenu = .search
                }
                self.homeViewModel.isSearching.toggle()
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
                    selectedMenu = .edit
                }
                homeViewModel.isEditing.toggle()
            }) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 17.68))
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    homeViewModel.isSettingMenu = true
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
    
    private enum ErrorStatus {
        case accessError
        case invalidURL
        case etc
    }
    
    private func importPDFToDevice(result: Result<[Foundation.URL], any Error>) {
        switch result {
        case .success(let url):
            if let newPaperID = homeViewModel.uploadPDF(url: url) {
                selectedItemID = newPaperID
            } else {
                homeViewModel.errorStatus = .fileNameDuplication
                homeViewModel.isErrorOccured.toggle()
            }
        case .failure(let error):
            print(String(describing: error))
            homeViewModel.errorStatus = .failedToAccessingSecurityScope
            homeViewModel.isErrorOccured.toggle()
        }
    }
}

/// 검색 화면 버튼 뷰
private struct SearchMenuView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @Binding var selectedMenu: Options
    
    // 검색 버튼 클릭 시 검색창 자동 포커싱
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            SearchBar()
                .frame(width: 400)
                .focused($isSearchFieldFocused)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedMenu = .main
                }
                self.homeViewModel.isSearching.toggle()
                homeViewModel.searchText = ""
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
    
    @Binding var selectedMenu: Options
    
    @State var isDeleteConfirm: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                homeViewModel.isMovingFolder.toggle()
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
                self.isDeleteConfirm.toggle()
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
                selectedMenu = .main
                homeViewModel.isEditing = false
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
            isPresented: $isDeleteConfirm,
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
    
    @Binding var createMovingFolder: Bool
    
    @State private var text: String = ""
    
    let folder: Folder?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(action: {
                        if homeViewModel.isEditingFolder {
                            homeViewModel.isEditingFolder = false
                        } else if homeViewModel.createFolder {
                            homeViewModel.createFolder = false
                        } else {
                            homeViewModel.createMovingFolder.toggle()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if text.isEmpty { text = String(localized: "새 폴더") }
                        
                        if homeViewModel.isEditingFolder {
                            if let folder = folder {
                                homeViewModel.updateFolderInfo(at: folder.id, title: text, color: selectedColors.rawValue)
                                homeViewModel.selectedFolderID = nil
                                homeViewModel.isEditingFolder = false
                            }
                        } else if homeViewModel.createFolder {
                            // 최상위 단계와 폴더 진입 단계 구분
                            if homeViewModel.isAtRoot {
                                homeViewModel.createSubfolder(in: nil, title: text, color: selectedColors.rawValue)
                            } else {
                                switch homeViewModel.folderCreationPosition {
                                case .intoCurrent:
                                    homeViewModel.createSubfolderInSelectedFolder(title: text, color: selectedColors.rawValue)
                                case .aboveCurrent:
                                    homeViewModel.createFolderAboveSelectedFolder(title: text, color: selectedColors.rawValue)
                                }
                            }
                            homeViewModel.selectedFolderID = nil
                            homeViewModel.createFolder = false
                        } else {
                            if let folder = folder {
                                homeViewModel.createSubfolder(in: folder, title: text, color: selectedColors.rawValue)
                            } else {
                                homeViewModel.createSubfolder(in: nil, title: text, color: selectedColors.rawValue)
                            }
                            homeViewModel.createMovingFolder.toggle()
                        }
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
            if homeViewModel.isEditingFolder {
                if let folder = folder {
                    text = folder.title
                    selectedColors = FolderColors(rawValue: folder.color) ?? .folder1
                }
            }
        }
    }
}

/// 태그 생성 뷰
private struct CreateTagView: View {
    @EnvironmentObject private var tagViewModel: TagViewModel
    @State private var text: String = ""
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        tagViewModel.createTag = false
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
                            tagViewModel.createTag = false
                            return
                        }
                        if let _ = tagViewModel.tags.filter({$0.name == text}).first {
                            tagViewModel.createTag = false
                            tagViewModel.isTagDuplicate = true
                            
                        } else {
                            tagViewModel.createTag(name: text)
                            tagViewModel.createTag = false
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
        .animation(.easeInOut, value: tagViewModel.createTag)
        .animation(.easeInOut, value: tagViewModel.isTagDuplicate)
        .onChange(of: text) { _, newValue in
            if newValue.count > 30 {
                text = String(newValue.prefix(30))
            }
        }
    }
}
