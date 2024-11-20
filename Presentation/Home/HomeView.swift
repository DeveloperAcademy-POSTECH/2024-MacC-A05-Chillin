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
    
    @State var selectedMenu: Options = .main
    @State var selectedItemID: UUID?
    
    // 검색 모드 search text
    @State private var searchText: String = ""
    
    @State private var isStarSelected: Bool = false
    @State private var isFolderSelected: Bool = false
    
    @State private var isEditing: Bool = false
    @State private var selectedItems: Set<Int> = []
    
    @State private var isSearching: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var isEditingMemo: Bool = false
    
    @State private var createFolder: Bool = false
    @State private var isEditingFolder: Bool = false
    
    @State private var isFavoriteSelected: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ZStack {
                    Rectangle()
                        .foregroundStyle(.point1)
                    
                    HStack(spacing: 0) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 62, height: 50)
                            .padding(.vertical, 31)
                            .padding(.leading, 28)
                            .padding(.trailing, 36)
                        
                        Button(action: {
                            isFavoriteSelected = false
                        }) {
                            Text("전체")
                                .reazyFont(isFavoriteSelected ? .text1 : .button1)
                                .foregroundStyle(isFavoriteSelected ? .gray600 : .gray100)
                        }
                        
                        Rectangle()
                            .frame(width: 1, height: 16)
                            .foregroundStyle(.gray700)
                            .padding(.horizontal, 14)
                        
                        Button(action: {
                            // TODO: - [브리] 즐겨찾기 로직 수정 필요
                            isFavoriteSelected = true
                        }) {
                            Text("즐겨찾기")
                                .reazyFont(isFavoriteSelected ? .button1 : .text1)
                                .foregroundStyle(isFavoriteSelected ? .gray100 : .gray600)
                        }
                        
                        Spacer()
                        
                        switch selectedMenu {
                        case .main:
                            MainMenuView(
                                selectedMenu: $selectedMenu,
                                isSearching: $isSearching,
                                isEditing: $isEditing,
                                selectedItems: $selectedItems,
                                selectedItemID: $selectedItemID,
                                createFolder: $createFolder)
                            
                        case .search:
                            SearchMenuView(
                                selectedMenu: $selectedMenu,
                                searchText: $searchText,
                                isSearching: $isSearching)
                            
                        case .edit:
                            EditMenuView(
                                selectedMenu: $selectedMenu,
                                selectedItems: $selectedItems,
                                isEditing: $isEditing)
                        }
                    }
                }
                .frame(height: 80)
                
                PaperListView(
                    selectedItemID: $selectedItemID,
                    selectedItems: $selectedItems,
                    isEditing: $isEditing,
                    isSearching: $isSearching,
                    isEditingTitle: $isEditingTitle,
                    isEditingFolder: $isEditingFolder,
                    isEditingMemo: $isEditingMemo,
                    searchText: $searchText,
                    isFavoriteSelected: $isFavoriteSelected
                )
            }
            .blur(radius: isEditingTitle || isEditingMemo || createFolder || isEditingFolder ? 20 : 0)
            
            
            Color.black
                .opacity( isEditingTitle || isEditingMemo || createFolder || isEditingFolder ? 0.5 : 0)
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
                    isEditingFolder: $isEditingFolder,
                    folder: homeViewModel.folders.first { $0.id == selectedItemID! } ?? nil
                )
            }
        }
        .background(Color(hex: "F7F7FB"))
        .statusBarHidden()
        .animation(.easeInOut, value: isEditingTitle)
        .animation(.easeInOut, value: isEditingMemo)
        .animation(.easeInOut, value: isEditingFolder)
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
    @Binding var isSearching: Bool
    @Binding var isEditing: Bool
    
    @Binding var selectedItems: Set<Int>
    @Binding var selectedItemID: UUID?
    @Binding var createFolder: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                createFolder.toggle()
            }) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 16))
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
                    .font(.system(size: 16))
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedMenu = .search
                }
                isSearching.toggle()
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
            
            Button(action: {
                self.isFileImporterPresented.toggle()
            }) {
                Text("가져오기")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            }
            .padding(.trailing, 28)
        }
        .alert(isPresented: $errorAlert) {
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
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false,
            onCompletion: importPDFToDevice)
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
                errorAlert.toggle()
            }
        case .failure(let error):
            print(String(describing: error))
            homeViewModel.errorStatus = .failedToAccessingSecurityScope
            self.errorAlert.toggle()
        }
    }
}

/// 검색 화면 버튼 뷰
private struct SearchMenuView: View {
    @Binding var selectedMenu: Options
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            SearchBar(text: $searchText)
                .frame(width: 400)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedMenu = .main
                }
                isSearching.toggle()
                searchText = ""
            }, label: {
                Text("취소")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
        }
    }
}

/// 수정 화면 버튼 뷰
private struct EditMenuView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var isStarSelected: Bool = false
    
    @Binding var selectedMenu: Options
    @Binding var selectedItems: Set<Int>
    @Binding var isEditing: Bool
    
    
    var body: some View {
        HStack(spacing: 0) {
            let selectedIDs: [UUID] = selectedItems.compactMap { index in
                guard index < homeViewModel.paperInfos.count else { return nil }
                return homeViewModel.paperInfos[index].id
            }
            
            Button(action: {
                isStarSelected.toggle()
                homeViewModel.updatePaperFavorites(at: selectedIDs)
            }, label : {
                Image(systemName: isStarSelected ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
            
            Button(action: {
                homeViewModel.deletePDF(ids: selectedIDs)
            }, label: {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)        
            
            Button(action: {
                selectedMenu = .main
                isEditing = false
                selectedItems.removeAll()
                isStarSelected = false
            }, label: {
                Text("취소")
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
        }
    }
}

/// 논문 타이틀 수정 뷰
private struct RenamePaperTitleView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var text: String = ""
    
    @Binding var isEditingTitle: Bool
    
    @Binding var isEditingMemo: Bool
    
    let paperInfo: PaperInfo
    
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
                        TextField( isEditingTitle ? "제목을 입력해주세요." : "내용을 입력해주세요.", text: $text, axis: .vertical)
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
                                .padding(.bottom, isEditingTitle ? 0 : 15)
                                .padding(.trailing, isEditingTitle ? 10 : 15)
                                .onTapGesture {
                                    text = ""
                                }
                        }
                    }
                    
                    Text(isEditingTitle ? "논문 제목을 입력해 주세요" : "논문에 대한 메모를 남겨주세요")
                        .reazyFont(.button1)
                        .foregroundStyle(.comment)
                }
            }
        }
        .onAppear {
            if isEditingTitle {
                self.text = paperInfo.title
            } else {
                self.text = paperInfo.memo ?? ""
            }
        }
    }
}

private struct FolderView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @State private var selectedColors: FolderColors = .folder1
    
    @Binding var createFolder: Bool
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
                        } else {
                            createFolder.toggle()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18))
                            .foregroundStyle(.gray100)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if isEditingFolder {
                            if let folder = folder {
                                homeViewModel.updateFolderInfo(at: folder.id, title: text, color: selectedColors.rawValue)
                                isEditingFolder.toggle()
                            }
                        } else {
                            // 최상위 단계와 폴더 진입 단계 구분
                            if homeViewModel.isAtRoot {
                                homeViewModel.saveFolder(to: nil, title: text, color: selectedColors.rawValue)
                            } else {
                                homeViewModel.saveFolder(to: homeViewModel.currentFolder?.id, title: text, color: selectedColors.rawValue)
                            }
                            createFolder.toggle()
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
                        Image("folder")
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
                        TextField("폴더 제목을 입력해주세요.", text: $text, axis: .vertical)
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
