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
    
    @StateObject private var pdfFileManager: PDFFileManager = .init()
    
    @State var selectedMenu: Options = .main
    
    // 검색 모드 search text
    @State private var searchText: String = ""
    
    @State private var isStarSelected: Bool = false
    @State private var isFolderSelected: Bool = false
    
    @State private var isEditing: Bool = false
    @State private var selectedItems: Set<Int> = []
    
    @State private var isSearching: Bool = false
    
    var body: some View {
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
                            selectedItems: $selectedItems)
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
                    }
                }
            }
            .frame(height: 80)
            
            PaperListView(
                isEditing: $isEditing,
                isSearching: $isSearching
            )
            .environmentObject(pdfFileManager)
        }
        .background(Color(hex: "F7F7FB"))
        .overlay {
            if pdfFileManager.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .statusBarHidden()
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
            case .badRequest:
                Alert(
                    title: Text("잘못된 요청"),
                    message: Text("잘못된 요청이 왔어요."),
                    primaryButton: .default(Text("Ok")),
                    secondaryButton: .cancel())
            case .corruptedPDF:
                Alert(
                    title: Text("PDF OCR 안되어있음"),
                    message: Text("OCR ㄴㄴ"),
                    primaryButton: .default(Text("Ok")),
                    secondaryButton: .cancel())
            case .etc:
                Alert(title: Text("알 수 없는 에러"))
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false,
            onCompletion: importPDFToDevice)
    }
    
    private enum ErrorStatus {
        case badRequest
        case corruptedPDF
        case etc
    }
    
    private func importPDFToDevice(result: Result<[Foundation.URL], any Error>) {
        switch result {
        case .success(let url):
            Task.init {
                do {
                    try await pdfFileManager.uploadPDFFile(url: url)
                } catch {
                    print(String(describing: error))
                    
                    if let error = error as? NetworkManagerError {
                        switch error {
                        case .badRequest:
                            self.errorStatus = .badRequest
                            self.errorAlert.toggle()
                        case .corruptedPDF:
                            self.errorStatus = .corruptedPDF
                            self.errorAlert.toggle()
                        default:
                            break
                        }
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
    @State private var isStarSelected: Bool = false
    
    @Binding var selectedMenu: Options
    @Binding var selectedItems: Set<Int>
    @Binding var isEditing: Bool
    
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                // MARK: - 북마크 로직 확인 필요
                isStarSelected.toggle()
            }, label : {
                Image(systemName: isStarSelected ? "star.fill" : "star")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
            
            Button(action: {
                
            }, label: {
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 19)
                    .foregroundStyle(.gray100)
            })
            .padding(.trailing, 28)
            
            Button(action: {
                
            }, label: {
                Image(systemName: "square.and.arrow.up")
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
