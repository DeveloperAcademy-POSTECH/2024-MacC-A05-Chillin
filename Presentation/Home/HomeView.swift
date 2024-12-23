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
    
    @State var selectedItemID: UUID?
    
    @State private var isStarSelected: Bool = false
    @State private var isFolderSelected: Bool = false
    
    @State private var isEditing: Bool = false
    @State private var selectedItems: Set<UUID> = []
    
    @State private var isEditingTitle: Bool = false
    @State private var isEditingMemo: Bool = false
    
    // 폴더 추가 페이지 변수
    @State private var createFolder: Bool = false
    @State private var createMovingFolder: Bool = false
    @State private var isEditingFolder: Bool = false
    
    // 폴더 이동 변수
    @State private var isMovingFolder: Bool = false
    @State private var moveToFolderID: UUID? = nil
    
    // 폴더 메모 추가 변수
    @State private var isEditingFolderMemo: Bool = false
    
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
                            .onTapGesture(count: 5) {
                                NotificationCenter.default.post(name: .resetFlag, object: nil)
                            }
                        
                        if !homeViewModel.isSearching {
                            Button(action: {
                                homeViewModel.isFavoriteSelected = false
                            }) {
                                Text("전체")
                                    .reazyFont(homeViewModel.isFavoriteSelected ? .text1 : .button1)
                                    .foregroundStyle(homeViewModel.isFavoriteSelected ? .gray600 : .gray100)
                            }
                            
                            Rectangle()
                                .frame(width: 1, height: 16)
                                .foregroundStyle(.gray700)
                                .padding(.horizontal, 14)
                            
                            Button(action: {
                                homeViewModel.isFavoriteSelected = true
                            }) {
                                Text("즐겨찾기")
                                    .reazyFont(homeViewModel.isFavoriteSelected ? .button1 : .text1)
                                    .foregroundStyle(homeViewModel.isFavoriteSelected ? .gray100 : .gray600)
                            }
                        }
                        
                        Spacer()
                        
                        switch homeViewModel.selectedMenu {
                        case .main:
                            MainMenuView(
                                selectedMenu: $homeViewModel.selectedMenu,
                                isEditing: $isEditing,
                                selectedItems: $selectedItems,
                                selectedItemID: $selectedItemID,
                                createFolder: $createFolder)
                            
                        case .search:
                            SearchMenuView(selectedMenu: $homeViewModel.selectedMenu)
                            
                        case .edit:
                            EditMenuView(
                                selectedMenu: $homeViewModel.selectedMenu,
                                selectedItems: $selectedItems,
                                isEditing: $isEditing,
                                isMovingFolder: $isMovingFolder
                            )
                        }
                    }
                    .padding(.top, 46)
                    .padding([.leading, .bottom], 28)
                }
                .frame(height: 80)
                
                if homeViewModel.isSearching && homeViewModel.searchText.isEmpty {
                    SearchWordView()
                } else {
                    PaperListView(
                        selectedItemID: $selectedItemID,
                        selectedItems: $selectedItems,
                        isEditing: $isEditing,
                        isEditingTitle: $isEditingTitle,
                        isEditingFolder: $isEditingFolder,
                        isEditingMemo: $isEditingMemo,
                        isEditingFolderMemo: $isEditingFolderMemo,
                        isMovingFolder: $isMovingFolder
                    )
                }
            }
            .blur(radius: isEditingTitle || isEditingMemo || createFolder || isEditingFolder || createMovingFolder || isEditingFolderMemo ? 20 : 0)
            
            
            Color.black
                .opacity(isEditingTitle || isEditingMemo || createFolder || isEditingFolder || isMovingFolder || isEditingFolderMemo || homeViewModel.isSettingMenu ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)
            
            if isEditingTitle || isEditingMemo {
                RenamePaperTitleView(
                    isEditingTitle: $isEditingTitle,
                    isEditingMemo: $isEditingMemo,
                    paperInfo: homeViewModel.paperInfos.first { $0.id == selectedItemID! }!)
            }
            
            if createFolder || isEditingFolder {
                FolderView(
                    createFolder: $createFolder,
                    createMovingFolder: $createMovingFolder,
                    isEditingFolder: $isEditingFolder,
                    folder: homeViewModel.folders.first { $0.id == selectedItemID! } ?? nil
                )
            }
            
            if isEditingFolderMemo {
                if let folder = homeViewModel.folders.first(where: { $0.id == selectedItemID! }) {
                    FolderMemoView(
                        isEditingFolderMemo: $isEditingFolderMemo,
                        folder: folder
                    )
                }
            }
            
            // 폴더 이동 View
            if isMovingFolder {
                let itemsToMove: [FileSystemItem] = selectedItems.isEmpty
                ? (selectedItemID.flatMap { id in
                    homeViewModel.filteredLists.first(where: { $0.id == id })
                }).map { [$0] } ?? []
                : selectedItems.compactMap { id in
                    homeViewModel.filteredLists.first(where: { $0.id == id })
                }
                
                MoveFolderView(
                    createMovingFolder: $createMovingFolder,
                    isMovingFolder: $isMovingFolder,
                    items: itemsToMove,
                    selectedID: $moveToFolderID
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 740, height: 550)
                .blur(radius: createMovingFolder ? 20 : 0)
                .onDisappear {
                    selectedItems.removeAll()
                }
            }
            
            Color.black
                .opacity(createMovingFolder ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)
            
            // 폴더 이동 시 새 폴더 생성
            if createMovingFolder {
                let folder = homeViewModel.folders.first(where: { $0.id == moveToFolderID })
                FolderView(
                    createFolder: $createFolder,
                    createMovingFolder: $createMovingFolder,
                    isEditingFolder: $isEditingFolder,
                    folder: folder
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
        .animation(.easeInOut, value: isEditingTitle)
        .animation(.easeInOut, value: isEditingMemo)
        .animation(.easeInOut, value: isEditingFolder)
        .alert(isPresented: $homeViewModel.isErrorOccured) {
            // TODO: 예외 처리 수정 필요
            switch homeViewModel.errorStatus {
            case .failedToAccessingSecurityScope:
                Alert(
                    title: Text("파일 접근이 불가능합니다."),
                    message: Text("다른 파일을 선택해주세요."),
                    dismissButton: .default(Text("Ok")))
            case .fileNameDuplication:
                Alert(
                    title: Text("중복된 파일 이름이 있습니다."),
                    message: Text("파일 이름을 수정해주세요."),
                    dismissButton: .default(Text("Ok")))
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
    @Binding var isEditing: Bool
    
    @Binding var selectedItems: Set<UUID>
    @Binding var selectedItemID: UUID?
    @Binding var createFolder: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                createFolder.toggle()
            }) {
                Image(.newfolder)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 21, height: 20)
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
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
                isEditing.toggle()
                selectedItems.removeAll()
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
            SearchBar(text: $homeViewModel.searchText)
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
    @Binding var selectedItems: Set<UUID>
    @Binding var isEditing: Bool
    @Binding var isMovingFolder: Bool
    
    @State var isDeleteConfirm: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            /*
            let containsFolder = items.contains { file in
                if case .folder = file {
                    return true
                }
                return false
            }
            
            Button(action: {
                // TODO: - 복제 버튼 활성화 필요
            }, label: {
                Image(.copy)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(containsFolder ? .gray550 : .gray100)
            })
            .padding(.trailing, 28)
            .disabled(containsFolder)
            */
            Button(action: {
                self.isMovingFolder.toggle()
            }, label: {
                Image(.move)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(self.selectedItems.isEmpty ? .gray550 : .gray100)
            })
            .padding(.trailing, 28)
            
            Button(action: {
                self.isDeleteConfirm.toggle()
            }, label: {
                Image(.trash)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 17, height: 17)
                    .foregroundStyle(self.selectedItems.isEmpty ? .gray550 : .gray100)
            })
            .disabled(self.selectedItems.isEmpty)
            .padding(.trailing, 28)
            
            Button(action: {
                selectedMenu = .main
                isEditing = false
                selectedItems.removeAll()
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
            presenting: selectedItems
        ) { itemList in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                let items: [FileSystemItem] = itemList.compactMap { id in
                    homeViewModel.filteredLists.first(where: { $0.id == id })
                }
                
                homeViewModel.deleteFiles(items)
                selectedItems.removeAll()
            }
        } message: { itemList in
            Text("삭제된 파일은 복구할 수 없습니다.")
        }
    }
}

/// 논문 타이틀 수정 뷰
struct RenamePaperTitleView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var text: String = ""
    
    @Binding var isEditingTitle: Bool
    
    @Binding var isEditingMemo: Bool
    
    let paperInfo: PaperInfo
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button {
                        if isEditingTitle {
                            isEditingTitle.toggle()
                        } else {
                            isEditingMemo = false
                        }
                        if self.homeViewModel.memoText.isEmpty {
                            self.homeViewModel.changedMemo = nil
                        } else {
                            self.homeViewModel.changedMemo = text
                        }
                        isTextFieldFocused = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                    }
                    .foregroundStyle(.gray100)
                    .padding(28)
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditingTitle {
                            homeViewModel.updateTitle(at: paperInfo.id, title: text)
                            isEditingTitle = false
                        } else {
                            homeViewModel.updateMemo(at: paperInfo.id, memo: text)
                            self.homeViewModel.memoText = text
                            isEditingMemo = false
                        }
                        isTextFieldFocused = false
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
                    .padding(28)
                }
                
                Spacer()
            }
            HStack(spacing: 54) {
                Image(uiImage: .init(data: paperInfo.thumbnail)!)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 196)
                
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .frame(width: 400, height: isEditingTitle ? 52 : 180)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray400)
                            .frame(width: 400, height: isEditingTitle ? 52 : 180)
                    }
                    .frame(width: 400, height: isEditingTitle ? 52 : 180)
                    .overlay(alignment: isEditingTitle ? .center : .topLeading) {
                        TextField(isEditingTitle ? "제목을 입력해주세요." : "내용을 입력해주세요.", text: $text, axis: isEditingTitle ? .horizontal : .vertical)
                            .lineLimit( isEditingTitle ? 1 : 6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, isEditingTitle ? 0 : 16)
                            .font(.custom(ReazyFontType.pretendardMediumFont, size: 16))
                            .foregroundStyle(.gray800)
                    }
                    .overlay(alignment: isEditingTitle ? .trailing : .bottomTrailing) {
                        if !self.text.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                                .background(.gray100)
                                .padding(.bottom, isEditingTitle ? 0 : 15)
                                .padding(.trailing, isEditingTitle ? 10 : 15)
                                .onTapGesture {
                                    text = ""
                                }
                        }
                    }
                    .focused($isTextFieldFocused)
                    
                    Text(isEditingTitle ? "논문 제목을 입력해 주세요" : "논문에 대한 메모를 남겨주세요")
                        .reazyFont(.button1)
                        .foregroundStyle(.comment)
                }
            }
        }
        .onAppear {
            if isEditingTitle {
                if let title = homeViewModel.changedTitle {
                    self.text = title
                } else {
                    self.text = paperInfo.title
                }
            } else {
                self.text = paperInfo.memo ?? ""
            }
            
            isTextFieldFocused = true
        }
    }
}

/// 폴더 생성 뷰
struct FolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var selectedColors: FolderColors = .folder1
    
    /* [세 가지 케이스 분리]
     - createFolder: 메인 화면에서 폴더 생성
     - createMovingFolder: 폴더 이동 시 새로운 폴더 생성
     - isEditingFolder: 폴더 정보 수정
     */
    @Binding var createFolder: Bool
    @Binding var createMovingFolder: Bool
    @Binding var isEditingFolder: Bool
    
    @State private var text: String = ""
    
    let folder: Folder?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(action: {
                        if isEditingFolder {
                            isEditingFolder.toggle()
                        } else if createFolder {
                            createFolder.toggle()
                        } else {
                            createMovingFolder.toggle()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if text.isEmpty { text = "새 폴더" }
                        
                        if isEditingFolder {
                            if let folder = folder {
                                homeViewModel.updateFolderInfo(at: folder.id, title: text, color: selectedColors.rawValue)
                                isEditingFolder.toggle()
                            }
                        } else if createFolder {
                            // 최상위 단계와 폴더 진입 단계 구분
                            if homeViewModel.isAtRoot {
                                homeViewModel.saveFolder(to: nil, title: text, color: selectedColors.rawValue)
                            } else {
                                homeViewModel.saveFolder(to: homeViewModel.currentFolder?.id, title: text, color: selectedColors.rawValue)
                            }
                            createFolder.toggle()
                        } else {
                            if let folder = folder {
                                homeViewModel.saveFolder(to: folder.id, title: text, color: selectedColors.rawValue)
                            } else {
                                homeViewModel.saveFolder(to: nil, title: text, color: selectedColors.rawValue)
                            }
                            createMovingFolder.toggle()
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
            if isEditingFolder {
                if let folder = folder {
                    text = folder.title
                    selectedColors = FolderColors(rawValue: folder.color) ?? .folder1
                }
            }
        }
    }
}

/// 폴더 메모 생성 & 수정 뷰
private struct FolderMemoView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var selectedColors: FolderColors
    
    @Binding var isEditingFolderMemo: Bool
    
    @State private var text: String = ""
    
    let folder: Folder
    
    @FocusState private var isTextFieldFocused: Bool
    
    init(
        isEditingFolderMemo: Binding<Bool>,
        folder: Folder
    ) {
        self._isEditingFolderMemo = isEditingFolderMemo
        self.folder = folder
        selectedColors = FolderColors(rawValue: folder.color) ?? .folder1
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button(action: {
                        if self.homeViewModel.memoText.isEmpty {
                            self.homeViewModel.changedMemo = nil
                        } else {
                            self.homeViewModel.changedMemo = text
                        }
                        self.isEditingFolderMemo.toggle()
                        self.isTextFieldFocused = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        self.homeViewModel.updateFolderMemo(at: folder.id, memo: text)
                        self.homeViewModel.memoText = text
                        self.isEditingFolderMemo.toggle()
                        self.isTextFieldFocused = false
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
                        Image("folder")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 105)
                    )
                    .padding(.trailing, 54)
                    .padding(.bottom, 26)
                
                VStack(spacing: 0) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .foregroundStyle(.gray100)
                            .frame(width: 400, height: 180)
                        
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray400)
                            .frame(width: 400, height: 180)
                    }
                    .frame(width: 400, height: 180)
                    .overlay(alignment: .topLeading) {
                        TextField("폴더에 대한 메모를 남겨주세요.", text: $text, axis: .vertical)
                            .lineLimit(6)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .font(.custom(ReazyFontType.pretendardMediumFont, size: 16))
                            .foregroundStyle(.gray800)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if !self.text.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                                .padding(.bottom, 15)
                                .padding(.trailing, 15)
                                .onTapGesture {
                                    text = ""
                                }
                        }
                    }
                    .padding(.bottom, 16)
                    .focused($isTextFieldFocused)
                    
                    Text("폴더 제목을 입력해 주세요")
                        .reazyFont(.button1)
                        .foregroundStyle(.comment)
                }
            }
        }
        .onAppear {
            if isEditingFolderMemo {
                self.text = folder.memo ?? ""
            }
            self.isTextFieldFocused = true
        }
    }
}
