//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI

struct PaperListView: View {
    @EnvironmentObject var pdfFileManager: PDFFileManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    @State private var selectedPaper: Int = 0
    @State var selectedItems: Set<Int> = []
    @State private var isFavoritesSelected: Bool = false

    @Binding var isEditing: Bool
    @Binding var isSearching: Bool
    
    
    var body: some View {
        // 화면 비율에 따라서 리스트 크기 설정 (반응형 UI)
        GeometryReader { geometry in
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Spacer()
                        
                        Button(action: {
                            isFavoritesSelected = false
                        }, label: {
                            Text("전체 논문")
                                .reazyFont(isFavoritesSelected ? .h2 : .text3)
                                .foregroundStyle(isFavoritesSelected ? .primary4 : .primary1)
                        })
                        
                        Rectangle()
                            .foregroundStyle(.gray500)
                            .frame(width: 1, height: 20)
                            .padding(.horizontal, 16)
                        
                        Button(action: {
                            isFavoritesSelected = true
                            // TODO: - 즐겨찾기 filter 적용 필요
                        }, label: {
                            Text("즐겨찾기")
                                .reazyFont(isFavoritesSelected ? .text3 : .h2)
                                .foregroundStyle(isFavoritesSelected ? .primary1 : .primary4)
                        })
                        
                        Spacer()
                    }
                    .padding(.leading, 28)
                    .padding(.vertical, 17)
                    
                    Divider()
                    
                    // MARK: - CoreData
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<pdfFileManager.paperInfos.count, id: \.self) { index in
                                PaperListCell(
                                    title: pdfFileManager.paperInfos[index].title,
                                    date: pdfFileManager.paperInfos[index].dateTime,
                                    isSelected: selectedPaper == index,
                                    isEditing: isEditing,
                                    isEditingSelected: selectedItems.contains(index),
                                    onSelect: {
                                        if !isEditing {
                                            if selectedPaper == index {
                                                navigateToPaper()
                                            }
                                            else {
                                                selectedPaper = index
                                            }
                                        }
                                    },
                                    onEditingSelect: {
                                        if isEditing {
                                            if selectedItems.contains(index) {
                                                selectedItems.remove(index)
                                            } else {
                                                selectedItems.insert(index)
                                            }
                                        }
                                    })
                                
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.primary3)
                            }
                        }
                    }
                }
                .frame(width: isEditing || isSearching ? geometry.size.width : geometry.size.width * 0.7)
                .background(.gray300)
                
                // 편집 모드 & 검색 모드에서는 문서 정보가 보이지 않아야 함
                if !isEditing && !isSearching {
                    Rectangle()
                        .frame(width: 1)
                        .foregroundStyle(.primary3)
                    
                    VStack(spacing: 0) {
                        // MARK: - 썸네일 이미지 수정 필요
                        if !pdfFileManager.paperInfos.isEmpty {
                            PaperInfoView(
                                image: pdfFileManager.paperInfos[selectedPaper].thumbnail,
                                title: pdfFileManager.paperInfos[selectedPaper].title,
                                author: pdfFileManager.paperInfos[selectedPaper].author,
                                year: pdfFileManager.paperInfos[selectedPaper].year,
                                pages: pdfFileManager.paperInfos[selectedPaper].pages,
                                publisher: pdfFileManager.paperInfos[selectedPaper].publisher,
                                onNavigate: {
                                    if !isEditing {
                                        navigateToPaper()
                                    }
                                }
                            )
                        }
                    }
                    .animation(.easeInOut, value: isEditing)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .gray300, location: 0),
                                .init(color: Color(hex: "DADBEA"), location: isEditing ? 3.5 : 4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .background(.gray200)
            .ignoresSafeArea()
        }
    }
}


extension PaperListView {
    private func navigateToPaper() {
        var isStale = false
        let data = pdfFileManager.paperInfos[selectedPaper].url
        
        guard let url = try? URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            print("bookmartdata to url failed")
            return
        }
        
        if isStale {
            print("Bookmark(\(url.lastPathComponent)) is stale")
            guard let updatedBookmark = try? url.bookmarkData(options: .minimalBookmark) else {
                print("Unable to create bookmark")
                return
            }
            // TODO: URL 데이터 업데이트 필요
        }
        
        if url.startAccessingSecurityScopedResource() {
            navigationCoordinator.push(.mainPDF(url: url))
            url.stopAccessingSecurityScopedResource()
        }
    }
}


#Preview {
    let manager = PDFFileManager(paperService: PaperDataService())
    
    PaperListView(isEditing: .constant(false), isSearching: .constant(false))
        .environmentObject(manager)
        .onAppear {
            manager.uploadSampleData()
        }
}
