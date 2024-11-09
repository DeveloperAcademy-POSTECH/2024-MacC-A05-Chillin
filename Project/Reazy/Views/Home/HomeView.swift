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
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    @StateObject private var pdfFileManager: PDFFileManager = .init(paperService: PaperDataService.shared)
    
    @State var selectedMenu: Options = .main
    @State var selectedPaperID: UUID?
    
    // 검색 모드 search text
    @State private var searchText: String = ""
    
    @State private var isStarSelected: Bool = false
    @State private var isFolderSelected: Bool = false
    
    @State private var isEditing: Bool = false
    @State private var selectedItems: Set<Int> = []
    
    @State private var isSearching: Bool = false
    @State private var isEditingTitle: Bool = false
    @State private var isEditingMemo: Bool = false
    
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
                            .frame(width: 54, height: 50)
                            .padding(.vertical, 31)
                            .padding(.leading, 28)
                        
                        Spacer()
                        
                        switch selectedMenu {
                        case .main:
                            MainMenuView(
                                selectedMenu: $selectedMenu,
                                isSearching: $isSearching,
                                isEditing: $isEditing,
                                selectedItems: $selectedItems,
                                selectedPaperID: $selectedPaperID)
                            .environmentObject(pdfFileManager)
                            
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
                            .environmentObject(pdfFileManager)
                        }
                    }
                }
                .frame(height: 80)
                
                PaperListView(
                    selectedPaperID: $selectedPaperID,
                    selectedItems: $selectedItems,
                    isEditing: $isEditing,
                    isSearching: $isSearching,
                    isEditingTitle: $isEditingTitle,
                    isEditingMemo: $isEditingMemo,
                    searchText: $searchText
                )
                .environmentObject(pdfFileManager)
            }
            .blur(radius: isEditingTitle || isEditingMemo ? 20 : 0)
            
            
            Color.black
                .opacity( isEditingTitle || isEditingMemo ? 0.5 : 0)
                .ignoresSafeArea(edges: .bottom)

            
            if isEditingTitle || isEditingMemo {
                RenamePaperTitleView(
                    isEditingTitle: $isEditingTitle,
                    isEditingMemo: $isEditingMemo,
                    paperInfo: pdfFileManager.paperInfos.first { $0.id == selectedPaperID! }!)
                    .environmentObject(pdfFileManager)
            }
        }
        .background(Color(hex: "F7F7FB"))
        .overlay {
            if pdfFileManager.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .statusBarHidden()
        .animation(.easeInOut, value: isEditingTitle)
        .animation(.easeInOut, value: isEditingMemo)
    }
}

#Preview {
    HomeView()
}


/// 기본 화면 버튼 뷰
private struct MainMenuView: View {
    @EnvironmentObject var pdfFileManager: PDFFileManager
    
    @State private var isFileImporterPresented: Bool = false
    @State private var errorAlert: Bool = false
    @State private var errorStatus: ErrorStatus = .etc
    
    @Binding var selectedMenu: Options
    @Binding var isSearching: Bool
    @Binding var isEditing: Bool
    @Binding var selectedItems: Set<Int>
    @Binding var selectedPaperID: UUID?
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedMenu = .search
                }
                isSearching.toggle()
            }) {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
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
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
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
            switch errorStatus {
            case .accessError:
                Alert(
                    title: Text("파일 접근이 불가능합니다."),
                    message: Text("다른 파일을 선택해주세요"),
                    dismissButton: .default(Text("Ok")))
            case .invalidURL:
                Alert(
                    title: Text("잘못된 파일 경로"),
                    message: Text("파일이 올바른 경로에 있는지 확인해주세요"),
                    dismissButton: .default(Text("Ok")))
                
            case .etc:
                Alert(title: Text("알 수 없는 에러가 발생했습니다."))
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
            do {
                if let newPaperID = try pdfFileManager.uploadPDFFile(url: url) {
                    selectedPaperID = newPaperID
                }
            } catch {
                print(String(describing: error))
                
                if let error = error as? PDFUploadError {
                    switch error {
                    case .failedToAccessingSecurityScope:
                        self.errorStatus = .accessError
                        self.errorAlert.toggle()
                    case .invalidURL:
                        self.errorStatus = .invalidURL
                        self.errorAlert.toggle()
                    }
                }
            }
        case .failure(let error):
            print(String(describing: error))
            self.errorStatus = .etc
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
    @EnvironmentObject var pdfFileManager: PDFFileManager
    @State private var isStarSelected: Bool = false
    
    @Binding var selectedMenu: Options
    @Binding var selectedItems: Set<Int>
    @Binding var isEditing: Bool
    
    
    var body: some View {
        HStack(spacing: 0) {
            let selectedIDs: [UUID] = selectedItems.compactMap { index in
                guard index < pdfFileManager.paperInfos.count else { return nil }
                return pdfFileManager.paperInfos[index].id
            }
            
            Button(action: {
                isStarSelected.toggle()
                pdfFileManager.updateFavorites(at: selectedIDs)
            }, label : {
                Image(systemName: isStarSelected ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
            
            Button(action: {
                pdfFileManager.deletePDFFiles(at: selectedIDs)
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
    @EnvironmentObject private var pdfFileManager: PDFFileManager
    
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
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17)
                    }
                    .foregroundStyle(.gray100)
                    .padding(28)
                    
                    Spacer()
                    
                    Button("완료") {
                        if isEditingTitle {
                            pdfFileManager.updateTitle(at: paperInfo.id, title: text)
                            isEditingTitle = false
                        } else {
                            // MARK: - 메모 업데이트 메소드 구현 완료
                            pdfFileManager.updateMemo(at: paperInfo.id, memo: text)
                            isEditingMemo = false
                        }
                    }
                    .reazyFont(.button1)
                    .foregroundStyle(.gray100)
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
