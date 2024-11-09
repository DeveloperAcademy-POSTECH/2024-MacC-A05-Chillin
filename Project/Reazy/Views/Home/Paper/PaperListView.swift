//
//  PaperListView.swift
//  Reazy
//
//  Created by 유지수 on 10/17/24.
//

import SwiftUI
import Combine

struct PaperListView: View {
    @EnvironmentObject var pdfFileManager: PDFFileManager
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    @Binding var selectedPaperID: UUID?
    @Binding var selectedItems: Set<Int>
    @State private var isFavoritesSelected: Bool = false
    
    @Binding var isEditing: Bool
    @Binding var isSearching: Bool
    @Binding var isEditingTitle: Bool
    @Binding var searchText: String
    
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var timerCancellable: Cancellable?
    
    var filteredPaperInfos: [PaperInfo] {
        var infos = isFavoritesSelected
        ? pdfFileManager.paperInfos.filter { $0.isFavorite }.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        : pdfFileManager.paperInfos.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        
        if !searchText.isEmpty {
            infos = infos.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        return infos
    }
    
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
                    
                    if isSearching && filteredPaperInfos.isEmpty {
                        Spacer()
                        
                        Text("\"\(searchText)\"와\n일치하는 결과가 없어요")
                            .reazyFont(.h5)
                            .foregroundStyle(.gray600)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, keyboardHeight)
                        
                        Spacer()
                    } else {
                        // MARK: - CoreData
                        if filteredPaperInfos.isEmpty {
                            VStack(spacing: 11) {
                                Spacer()
                                Image(.homePlaceholder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 110)
                                
                                Text("새로운 논문을 가져와주세요")
                                    .reazyFont(.h5)
                                    .foregroundStyle(.gray550.opacity(0.3))
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(0..<filteredPaperInfos.count, id: \.self) { index in
                                        PaperListCell(
                                            title: filteredPaperInfos[index].title,
                                            date: timeAgoString(from: filteredPaperInfos[index].lastModifiedDate),
                                            isSelected: selectedPaperID == filteredPaperInfos[index].id,
                                            isEditing: isEditing,
                                            isEditingSelected: selectedItems.contains(index),
                                            onSelect: {
                                                if !isEditing {
                                                    if selectedPaperID == filteredPaperInfos[index].id {
                                                        navigateToPaper()
                                                        pdfFileManager.updateLastModifiedDate(at: filteredPaperInfos[index].id, lastModifiedDate: Date())
                                                    }
                                                    else {
                                                        selectedPaperID = filteredPaperInfos[index].id
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
                                            }
                                        )
                                        
                                        Rectangle()
                                            .frame(height: 1)
                                            .foregroundStyle(.primary3)
                                    }
                                }
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
                        if !filteredPaperInfos.isEmpty,
                           let selectedPaperIndex = filteredPaperInfos.firstIndex(where: { $0.id == selectedPaperID }) {
                            PaperInfoView(
                                id: filteredPaperInfos[selectedPaperIndex].id,
                                image: filteredPaperInfos[selectedPaperIndex].thumbnail,
                                title: filteredPaperInfos[selectedPaperIndex].title,
                                author: filteredPaperInfos[selectedPaperIndex].author,
                                pages: filteredPaperInfos[selectedPaperIndex].pages,
                                publisher: filteredPaperInfos[selectedPaperIndex].publisher,
                                dateTime: filteredPaperInfos[selectedPaperIndex].dateTime,
                                isFavorite: filteredPaperInfos[selectedPaperIndex].isFavorite,
                                isStarSelected: filteredPaperInfos[selectedPaperIndex].isFavorite,
                                isEditingTitle: $isEditingTitle,
                                onNavigate: {
                                    if !isEditing {
                                        navigateToPaper()
                                    }
                                },
                                onDelete: {
                                    if filteredPaperInfos.isEmpty {
                                        selectedPaperID = nil
                                    } else {
                                        selectedPaperID = filteredPaperInfos.first?.id
                                    }
                                }
                            )
                            .environmentObject(pdfFileManager)
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
            .onAppear {
                initializeSelectedPaperID()
                
                // 키보드 높이에 맞게 검색 Text 위치 조정
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        withAnimation {
                            self.keyboardHeight = keyboardFrame.height
                        }
                    }
                }
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    withAnimation {
                        self.keyboardHeight = 0
                    }
                }
            }
            .onDisappear {
                // Notification 제거
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            }
            .onChange(of: selectedPaperID) {
                initializeSelectedPaperID()
            }
            .background(.gray200)
            .ignoresSafeArea()
        }
    }
}


extension PaperListView {
    private func navigateToPaper() {
        guard let selectedPaperID = selectedPaperID,
              let selectedPaper = pdfFileManager.paperInfos.first(where: { $0.id == selectedPaperID }) else {
            return
        }
        
        var isStale = false
        let data = selectedPaper.url
        
        guard let url = try? URL.init(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale) else {
            print("bookmartdata to url failed")
            return
        }
        
        if isStale {
            print("Bookmark(\(url.lastPathComponent)) is stale")
            guard let _ = try? url.bookmarkData(options: .minimalBookmark) else {
                print("Unable to create bookmark")
                return
            }
            // TODO: URL 데이터 업데이트 필요
        }
        
        if url.startAccessingSecurityScopedResource() {
            navigationCoordinator.push(.mainPDF(paperInfo: selectedPaper))
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    private func initializeSelectedPaperID() {
        let filteredPaperInfos =
        isFavoritesSelected
        ? pdfFileManager.paperInfos.filter { $0.isFavorite }.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        : pdfFileManager.paperInfos.sorted(by: { $0.lastModifiedDate > $1.lastModifiedDate })
        
        if selectedPaperID == nil, let firstPaper = filteredPaperInfos.first {
            selectedPaperID = firstPaper.id
        }
        
        pdfFileManager.paperInfos = filteredPaperInfos
    }
}

extension PaperListView {
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "오늘 HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "어제 HH:mm"
            return dateFormatter.string(from: date)
        } else {
            // 이틀 전 이상의 날짜 포맷으로 반환
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy. MM. dd. a h:mm"
            dateFormatter.amSymbol = "오전"
            dateFormatter.pmSymbol = "오후"
            return dateFormatter.string(from: date)
        }
    }
}


#Preview {
    let manager = PDFFileManager(paperService: PaperDataService.shared)
    
    PaperListView(
        selectedPaperID: .constant(nil),
        selectedItems: .constant([]),
        isEditing: .constant(false),
        isSearching: .constant(false),
        isEditingTitle: .constant(false),
        searchText: .constant("")
    )
    .environmentObject(manager)
    .onAppear {
        manager.uploadSampleData()
    }
}
