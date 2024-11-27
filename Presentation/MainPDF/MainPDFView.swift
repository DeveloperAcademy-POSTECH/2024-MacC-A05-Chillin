//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PDFKit

enum LayoutOrientation {
    case vertical, horizontal
}

struct MainPDFView: View {
    
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    @StateObject public var pdfInfoMenuViewModel: PDFInfoMenuViewModel
    @StateObject public var mainPDFViewModel: MainPDFViewModel
    @StateObject private var floatingViewModel: FloatingViewModel = .init()
    @StateObject public var commentViewModel: CommentViewModel
    @StateObject public var focusFigureViewModel: FocusFigureViewModel
    @StateObject public var pageListViewModel: PageListViewModel
    @StateObject public var searchViewModel: SearchViewModel
    @StateObject public var indexViewModel: IndexViewModel
    
    @State private var selectedIndex: Int = 0
    @State private var isReadModeFirstSelected: Bool = false
    
    @State private var isListSelected: Bool = false
    @State private var isFigSelected: Bool = false
    @State private var isCollectionSelected: Bool = false
    @State private var isSearchSelected: Bool = false
    @State private var isReadMode: Bool = false
    
    @State private var isEditingTitle: Bool = false
    @State private var isEditingMemo: Bool = false
    @State private var isMovingFolder: Bool = false
    @State private var createMovingFolder: Bool = false
    
    @State private var moveToFolderID: UUID? = nil
    
    @State private var isVertical = false
    @State private var isModifyTitlePresented: Bool = false         // 타이틀 바꿀 때 활용하는 Bool값
    @State private var titleText: String = ""
    
    @State private var dragAmount: CGPoint?
    @State private var dragOffset: CGSize = .zero
    
    @State private var menuButtonPosition: CGPoint = .zero
    private let publisher = NotificationCenter.default.publisher(for: .isPDFInfoMenuHidden)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    ZStack {
                        HStack(spacing: 0) {
                            Button(action: {
                                navigationCoordinator.pop()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.clear)
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.gray800)
                                    )
                            }
                            .padding(.trailing, 24)
                            
                            Button(action: {
                                isListSelected.toggle()
                                isSearchSelected = false
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(isListSelected ? .primary1 : .clear)
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.index)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 18)
                                            .foregroundStyle(isListSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 24)
                            
                            Button(action: {
                                isSearchSelected.toggle()
                                isListSelected = false
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle( isSearchSelected ? .primary1 : .clear)
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.search)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 22)
                                            .foregroundStyle(isSearchSelected ? .gray100 : .gray800)
                                    )
                            }
                            
                            Rectangle()
                                .frame(width: 1.2, height: 16)
                                // TODO: - 집중모드 개선 후 삭제
                                .foregroundStyle(.clear)
                                // .foregroundStyle(.primary4)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                isReadMode.toggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle( isReadMode ? .primary1 : .clear )
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.focus)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 18)
                                            // TODO: - 집중모드 개선 후 삭제
                                            .foregroundStyle(.clear)
                                            // .foregroundStyle(isReadMode ? .gray100 : .gray800)
                                    )
                            }
                            .disabled(true) // TODO: - 집중모드 개선 후 삭제
                            
                            Spacer()
                            
                            Button(action: {
                                isFigSelected.toggle()
                                isCollectionSelected = false
                                
                                mainPDFViewModel.pdfDrawer.drawingTool = .none
                                mainPDFViewModel.pdfDrawer.endCaptureMode()
                                focusFigureViewModel.isCaptureMode = false
                                
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(isFigSelected ? .primary1 : .clear)
                                    .overlay (
                                        Text("Fig")
                                            .font(.system(size: 14))
                                            .foregroundStyle(isFigSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 25)
                            
                            Button(action: {
                                isCollectionSelected.toggle()
                                isFigSelected = false
                                
                                mainPDFViewModel.pdfDrawer.drawingTool = .none
                                mainPDFViewModel.pdfDrawer.endCaptureMode()
                                focusFigureViewModel.isCaptureMode = false
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(isCollectionSelected ? .primary1 : .clear)
                                    .overlay(
                                        Image(.window)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(isCollectionSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 25)

                            Button(action: {
                                withAnimation {
                                    mainPDFViewModel.isMenuSelected.toggle()
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(Color.clear)
                                    .overlay(
                                        Image(systemName: "ellipsis")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.gray800)
                                    )
                            }
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        // 버튼의 위치 정보 받아오기
                                        .onChange(of: geometry.frame(in: .global)) {  oldValue, newValue in
                                            menuButtonPosition = newValue.origin
                                        }
                                }
                            )
                        }
                        
                        HStack(spacing: 0) {
                            Spacer()
                            
                            ForEach(Buttons.allCases, id: \.self) { btn in
                                ButtonsView(button: $mainPDFViewModel.selectedButton, selectedButton: btn) {
                                    if mainPDFViewModel.selectedButton == btn {
                                        mainPDFViewModel.selectedButton = nil
                                        mainPDFViewModel.toolMode = .none
                                        mainPDFViewModel.pdfDrawer.drawingTool = .none
                                    } else {
                                        mainPDFViewModel.selectedButton = btn
                                        mainPDFViewModel.pdfDrawer.endCaptureMode()
                                        focusFigureViewModel.isCaptureMode = false
                                    }
                                    
                                    switch mainPDFViewModel.selectedButton {
                                    case .drawing:
                                        mainPDFViewModel.toolMode = .drawing
                                        mainPDFViewModel.pdfDrawer.drawingTool = .none
                                    case .comment:
                                        mainPDFViewModel.toolMode = .comment
                                        mainPDFViewModel.pdfDrawer.drawingTool = .none
                                    case .translate:
                                        NotificationCenter.default.post(name: .PDFViewSelectionChanged, object: nil)
                                        mainPDFViewModel.toolMode = .translate
                                        mainPDFViewModel.pdfDrawer.drawingTool = .none
                                    default:
                                        mainPDFViewModel.toolMode = .none
                                        mainPDFViewModel.pdfDrawer.drawingTool = .none
                                    }
                                }
                                .padding(.horizontal, 18)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                    .padding(.horizontal, 20)
                    .background(.primary3)
                    .zIndex(1)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color(hex: "CCCEE1"))
                        .zIndex(1)
                    
                    GeometryReader { geometry in
                        ZStack {
                            HStack(spacing: 0) {
                                ZStack {
                                    if isListSelected {
                                        HStack(spacing: 0) {
                                            MenuView()
                                                .environmentObject(mainPDFViewModel)
                                                .environmentObject(indexViewModel)
                                                .environmentObject(pageListViewModel)
                                                .frame(width: 252)
                                                .background(.gray100)
                                                .overlay(
                                                    Rectangle()
                                                        .frame(width: 1.5)
                                                        .foregroundStyle(.primary3),
                                                    alignment: .trailing
                                                )
                                                .transition(.move(edge: .leading))
                                        }
                                    }
                                    
                                    if isSearchSelected {
                                        OverlaySearchView(isSearchSelected: $isSearchSelected)
                                            .environmentObject(searchViewModel)
                                            .overlay(
                                                Rectangle()
                                                    .frame(width: 1.5)
                                                    .foregroundStyle(.primary3),
                                                alignment: .trailing
                                            )
                                            .transition(.move(edge: .leading))
                                    }
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    if isVertical {
                                        splitLayout(for: .vertical)
                                    } else {
                                        splitLayout(for: .horizontal)
                                    }
                                }
                                
                                Spacer()
                                
                                ZStack {
                                    if isFigSelected && !floatingViewModel.splitMode {
                                        HStack(spacing: 0) {
                                            FigureView(onSelect: { documentID, document, head in
                                                floatingViewModel.isFigure = true
                                                floatingViewModel.toggleSelection(for: documentID, document: document, head: head)
                                            })
                                            .environmentObject(mainPDFViewModel)
                                            .environmentObject(floatingViewModel)
                                            .environmentObject(focusFigureViewModel)
                                            .background(.white)
                                            .frame(width: geometry.size.width * 0.22)
                                            .transition(.move(edge: .leading))
                                            .overlay(
                                                Rectangle()
                                                    .frame(width: 1.5)
                                                    .foregroundStyle(.primary3),
                                                alignment: .leading
                                            )
                                        }
                                    }
                                    
                                    // TODO: - 모아보기 기능
                                    if isCollectionSelected && !floatingViewModel.splitMode {
                                        HStack(spacing: 0) {
                                            CollectionView(onSelect: { documentID, document, head in
                                                floatingViewModel.isFigure = false
                                                floatingViewModel.toggleSelection(for: documentID, document: document, head: head)
                                            })
                                            .environmentObject(mainPDFViewModel)
                                            .environmentObject(floatingViewModel)
                                            .environmentObject(focusFigureViewModel)
                                            .background(.white)
                                            .frame(width: geometry.size.width * 0.22)
                                            .transition(.move(edge: .leading))
                                            .overlay(
                                                Rectangle()
                                                    .frame(width: 1.5)
                                                    .foregroundStyle(.primary3),
                                                alignment: .leading
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.gray200)
                        .ignoresSafeArea()
                    }
                }
                .blur(radius: isEditingTitle || isEditingMemo || createMovingFolder ? 20 : 0)
                
                Color.black
                    .opacity(isEditingTitle || isEditingMemo || isMovingFolder || createMovingFolder ? 0.5 : 0)
                    .ignoresSafeArea(edges: .bottom)
                
                if mainPDFViewModel.toolMode == .drawing {
                    GeometryReader { gp in
                        ZStack {
                            HStack(spacing: 0) {
                                DrawingView(selectedButton: $mainPDFViewModel.selectedButton)
                                    .environmentObject(mainPDFViewModel)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.gray100)
                                    }
                                    .shadow(color: Color(hex: "05043E").opacity(0.1), radius: 20, x: 0, y: 4)
                                    .position(
                                        CGPoint(
                                            x: max(0, min(gp.size.width, (self.dragAmount?.x ?? 24) + dragOffset.width)),
                                            y: max(0, min(gp.size.height, (self.dragAmount?.y ?? gp.size.height / 2) + dragOffset.height))
                                        )
                                    )
                                    .highPriorityGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                self.dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                self.dragAmount = CGPoint(
                                                    x: (self.dragAmount?.x ?? 24) + value.translation.width,
                                                    y: (self.dragAmount?.y ?? gp.size.height / 2) + value.translation.height
                                                )
                                                self.dragOffset = .zero
                                            }
                                    )
                                    .animation(.bouncy(duration: 0.5), value: dragOffset)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 20)
                        .padding(.leading, isListSelected || isSearchSelected ? 272 : 20)
                    }
                }
                
                // MARK: - Floating 뷰
                FloatingViewsContainer(geometry: geometry)
                    .environmentObject(floatingViewModel)
                
                if mainPDFViewModel.isMenuSelected {
                    GeometryReader { gp in
                        ZStack {
                            PDFInfoMenu(
                                isEditingTitle: $isEditingTitle,
                                isEditingMemo: $isEditingMemo,
                                isMovingFolder: $isMovingFolder,
                                createMovingFolder: $createMovingFolder,
                                title: homeViewModel.changedTitle
                            )
                            .environmentObject(homeViewModel)
                            .environmentObject(mainPDFViewModel)
                            .environmentObject(pdfInfoMenuViewModel)
                            .transition(.opacity)
                            .animation(.easeInOut, value: mainPDFViewModel.isMenuSelected)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                        
                    }
                }
                
                if focusFigureViewModel.isEditFigName, let id = focusFigureViewModel.selectedID {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea(edges: .all)
                    
                    EditFigNameView(id: id)
                        .environmentObject(focusFigureViewModel)
                        .zIndex(1)
                }
                
                if isEditingTitle || isEditingMemo {
                    RenamePaperTitleView(
                        isEditingTitle: $isEditingTitle,
                        isEditingMemo: $isEditingMemo,
                        paperInfo: PDFSharedData.shared.paperInfo!
                    )
                }
                
                if isMovingFolder {
                    if let paperInfo = PDFSharedData.shared.paperInfo {
                        let itemsToMove: FileSystemItem = FileSystemItem.paper(paperInfo)
                        
                        MoveFolderView(
                            createMovingFolder: $createMovingFolder,
                            isMovingFolder: $isMovingFolder,
                            items: [itemsToMove],
                            selectedID: $moveToFolderID
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .frame(width: 740, height: 550)
                        .blur(radius: createMovingFolder ? 20 : 0)
                    }
                }
                
                Color.black
                    .opacity(createMovingFolder ? 0.5 : 0)
                    .ignoresSafeArea(edges: .bottom)
                
                if createMovingFolder {
                    let folder = homeViewModel.folders.first(where: { $0.id == moveToFolderID })
                    FolderView(
                        createFolder: .constant(false),
                        createMovingFolder: $createMovingFolder,
                        isEditingFolder: .constant(false),
                        folder: folder
                    )
                }
            }
        
            .navigationBarHidden(true)
            .onAppear {
                updateOrientation(with: geometry)
            }
            .onDisappear {
                mainPDFViewModel.savePDF(pdfView: mainPDFViewModel.pdfDrawer.pdfView)
            }
            .onChange(of: geometry.size) {
                updateOrientation(with: geometry)
            }
        }
    }
    
    @ViewBuilder
    private func mainView(isReadMode: Bool) -> some View {
        ZStack {
            OriginalView()
                .environmentObject(mainPDFViewModel)
                .environmentObject(floatingViewModel)
                .environmentObject(commentViewModel)
                .environmentObject(focusFigureViewModel)
                .environmentObject(pageListViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(indexViewModel)
            
            if isReadMode {
                ConcentrateView()
                    .environmentObject(focusFigureViewModel)
            }
        }
    }
    
    private func splitLayout(for orientation: LayoutOrientation) -> some View {
        Group {
            if orientation == .vertical {
                VStack(spacing: 0) {
                    layoutContent(for: orientation)
                }
            } else {
                HStack(spacing: 0) {
                    layoutContent(for: orientation)
                }
            }
        }
    }
    
    @ViewBuilder
    private func layoutContent(for orientation: LayoutOrientation) -> some View {
        if floatingViewModel.splitMode && !mainPDFViewModel.isPaperViewFirst,
           let splitDetails = floatingViewModel.getSplitDocumentDetails() {
            FloatingSplitView(
                documentID: splitDetails.documentID,
                document: splitDetails.document,
                head: splitDetails.head,
                isFigSelected: isFigSelected,
                isCollectionSelected: isCollectionSelected,
                onSelect: {
                    withAnimation {
                        mainPDFViewModel.isPaperViewFirst.toggle()
                    }
                }
            )
            .environmentObject(floatingViewModel)
            .environmentObject(focusFigureViewModel)
            
            divider(for: orientation)
        }
        
        ZStack {
            mainView(isReadMode: isReadMode)
            // 18 미만 버전에서 번역 모드 on 일 때 말풍선 띄우기
            if #unavailable(iOS 18.0) {
                if mainPDFViewModel.toolMode == .translate {
                    TranslateViewOlderVer()
                }
            } else {
                if mainPDFViewModel.toolMode == .translate && mainPDFViewModel.selectedText.isEmpty {
                    TemporaryAlertView(mode: "translate")
                }
            }
            if mainPDFViewModel.toolMode == .comment && mainPDFViewModel.selectedText.isEmpty {
                TemporaryAlertView(mode: "comment")
            }
            if isFigSelected && mainPDFViewModel.pdfDrawer.drawingTool == .lasso && focusFigureViewModel.isCaptureMode {
                TemporaryAlertView(mode: "lasso")
            }
        }
        .onReceive(publisher) { a in
            if let _ = a.userInfo?["hitted"] as? Bool {
                mainPDFViewModel.isMenuSelected = false
            }
        }
        
        if floatingViewModel.splitMode && mainPDFViewModel.isPaperViewFirst,
           let splitDetails = floatingViewModel.getSplitDocumentDetails() {
            divider(for: orientation)
            
            FloatingSplitView(
                documentID: splitDetails.documentID,
                document: splitDetails.document,
                head: splitDetails.head,
                isFigSelected: isFigSelected,
                isCollectionSelected: isCollectionSelected,
                onSelect: {
                    withAnimation {
                        mainPDFViewModel.isPaperViewFirst.toggle()
                    }
                }
            )
            .environmentObject(floatingViewModel)
            .environmentObject(focusFigureViewModel)
        }
    }
    
    @ViewBuilder
    private func divider(for orientation: LayoutOrientation) -> some View {
        if orientation == .vertical {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray300)
        } else {
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.gray300)
        }
    }
    
    // 기기의 방향에 따라 isVertical 상태를 업데이트하는 함수
    private func updateOrientation(with geometry: GeometryProxy) {
        isVertical = geometry.size.height > geometry.size.width
    }
}


/// 검색 뷰
private struct OverlaySearchView: View {
    @Binding var isSearchSelected: Bool
    
    var body: some View {
        SearchView()
    }
}

