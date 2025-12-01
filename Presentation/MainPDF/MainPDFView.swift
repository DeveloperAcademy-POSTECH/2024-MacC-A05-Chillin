//
//  PDFView.swift
//  Reazy
//
//  Created by 유지수 on 10/14/24.
//

import SwiftUI
import PDFKit


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
    @StateObject public var backPageBtnViewModel: BackPageBtnViewModel
    
    @State private var translationManager: TranslationManager = .init()
    
    
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
                                mainPDFViewModel.statusStack.menuToggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(mainPDFViewModel.statusStack.isMenuSelected ? .primary1 : .clear)
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.index)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 18)
                                            .foregroundStyle(mainPDFViewModel.statusStack.isMenuSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 24)
                            
                            Button(action: {
                                mainPDFViewModel.statusStack.searchToggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle(mainPDFViewModel.statusStack.isSearchSelected ? .primary1 : .clear)
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.search)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 22)
                                            .foregroundStyle(mainPDFViewModel.statusStack.isSearchSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 24)
                            
                            Button(action: {
                                mainPDFViewModel.statusStack.concentrateToggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle( mainPDFViewModel.statusStack.isConcentrateSelected ? .primary1 : .clear )
                                    .frame(width: 26, height: 26)
                                    .overlay (
                                        Image(.focus)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 18)
                                            .foregroundStyle(mainPDFViewModel.statusStack.isConcentrateSelected ? .gray100 : .gray800)
                                    )
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                mainPDFViewModel.statusStack.figureToggle()
                                mainPDFViewModel.pdfDrawer.endCaptureMode()
                                focusFigureViewModel.isCaptureMode = false
                                // TODO: QA Fig버튼 클릭
                                let articleId = PDFSharedData.shared.articleId()
                                AnalyticsManager.sendEvent(eventType: .figureButtonClick, parameters: articleId)
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(mainPDFViewModel.statusStack.isFigureSelected ? .primary1 : .clear)
                                    .overlay (
                                        Text("Fig")
                                            .font(.system(size: 14))
                                            .foregroundStyle(mainPDFViewModel.statusStack.isFigureSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 25)
                            
                            Button(action: {
                                mainPDFViewModel.statusStack.collectionToggle()
                                mainPDFViewModel.pdfDrawer.endCaptureMode()
                                focusFigureViewModel.isCaptureMode = false
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(mainPDFViewModel.statusStack.isCollectionSelected ? .primary1 : .clear)
                                    .overlay(
                                        Image(.window)
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 16, height: 16)
                                            .foregroundStyle(mainPDFViewModel.statusStack.isCollectionSelected ? .gray100 : .gray800)
                                    )
                            }
                            .padding(.trailing, 25)
                            
                            Button(action: {
                                withAnimation {
                                    mainPDFViewModel.statusStack.detailToggle()
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
                        }
                        
                        if !mainPDFViewModel.statusStack.isConcentrateSelected {
                            HStack(spacing: 0) {
                                Spacer()
                                
                                ForEach(Buttons.allCases, id: \.self) { btn in
                                    ButtonsView(selectedButton: btn) {
                                        mainPDFViewModel.statusStack.toggleCenterButton(button: btn)
                                    }
                                    .environmentObject(mainPDFViewModel)
                                    .padding(.horizontal, 18)
                                }
                                
                                Spacer()
                            }
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
                    
                    // MARK: - PDF뷰 영역
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            if mainPDFViewModel.statusStack.isMenuSelected {
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
                            
                            if mainPDFViewModel.statusStack.isSearchSelected {
                                SearchView()
                                    .environmentObject(searchViewModel)
                                    .overlay(
                                        Rectangle()
                                            .frame(width: 1.5)
                                            .foregroundStyle(.primary3),
                                        alignment: .trailing
                                    )
                                    .transition(.move(edge: .leading))
                            }
                            
                            MainOriginalView()
                                .environmentObject(mainPDFViewModel)
                                .environmentObject(floatingViewModel)
                                .environmentObject(commentViewModel)
                                .environmentObject(focusFigureViewModel)
                                .environmentObject(pageListViewModel)
                                .environmentObject(searchViewModel)
                                .environmentObject(indexViewModel)
                                .environmentObject(backPageBtnViewModel)
                                .environment(translationManager)
                            
                            if mainPDFViewModel.statusStack.isFigureSelected && !floatingViewModel.splitMode {
                                FigureView(onSelect: { id, documentID, document, head in
                                    floatingViewModel.isFigure = true
                                    floatingViewModel.toggleSelection(id: id, for: documentID, document: document, head: head)
                                    // TODO: QA 피규어 블록 클릭 수
                                    AnalyticsManager.sendEvent(
                                        eventType: .figureBlockClick,
                                        parameters: PDFSharedData.shared.articleId(), id.uuidString
                                    )
                                })
                                .environmentObject(mainPDFViewModel)
                                .environmentObject(floatingViewModel)
                                .environmentObject(focusFigureViewModel)
                                .background(.white)
                                .frame(width: 252)
                                .transition(.move(edge: .leading))
                                .overlay(
                                    Rectangle()
                                        .frame(width: 1.5)
                                        .foregroundStyle(.primary3),
                                    alignment: .leading
                                )
                            }
                            
                            if mainPDFViewModel.statusStack.isCollectionSelected && !floatingViewModel.splitMode {
                                CollectionView(onSelect: { id, documentID, document, head in
                                    floatingViewModel.isFigure = false
                                    floatingViewModel.toggleSelection(id: id, for: documentID, document: document, head: head)
                                })
                                .environmentObject(mainPDFViewModel)
                                .environmentObject(floatingViewModel)
                                .environmentObject(focusFigureViewModel)
                                .background(.white)
                                .frame(width: 252)
                                .transition(.move(edge: .leading))
                                .overlay(
                                    Rectangle()
                                        .frame(width: 1.5)
                                        .foregroundStyle(.primary3),
                                    alignment: .leading
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.gray200)
                        .ignoresSafeArea()
                    }
                }
                .blur(radius: mainPDFViewModel.mainPDFViewAction.blurConstant)
                
                if mainPDFViewModel.statusStack.isToolSelected {
                    GeometryReader { gp in
                        ZStack {
                            HStack(spacing: 0) {
                                DrawingView()
                                    .environmentObject(mainPDFViewModel)
                                    .background {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.gray100)
                                    }
                                    .shadow(color: Color(hex: "05043E").opacity(0.1), radius: 20, x: 0, y: 4)
                                    .position(
                                        CGPoint(
                                            x: max(0, min(gp.size.width, (mainPDFViewModel.dragAmount?.x ?? 24) + mainPDFViewModel.dragOffset.width)),
                                            y: max(0, min(gp.size.height, (mainPDFViewModel.dragAmount?.y ?? gp.size.height / 2) + mainPDFViewModel.dragOffset.height))
                                        )
                                    )
                                    .highPriorityGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                mainPDFViewModel.dragOffset = value.translation
                                            }
                                            .onEnded { value in
                                                mainPDFViewModel.dragAmount = CGPoint(
                                                    x: (mainPDFViewModel.dragAmount?.x ?? 24) + value.translation.width,
                                                    y: (mainPDFViewModel.dragAmount?.y ?? gp.size.height / 2) + value.translation.height
                                                )
                                                mainPDFViewModel.dragOffset = .zero
                                            }
                                    )
                                    .animation(.bouncy(duration: 0.5), value: mainPDFViewModel.dragOffset)
                                Spacer()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 20)
                        .padding(.leading, mainPDFViewModel.statusStack.isMenuSelected || mainPDFViewModel.statusStack.isSearchSelected ? 272 : 20)
                    }
                }
                
                if mainPDFViewModel.statusStack.isHighlightSelected {
                    TemporaryAlertView(mode: "drawing")
                }
                
                if mainPDFViewModel.statusStack.isCommentSelected && mainPDFViewModel.selectedText.isEmpty {
                    TemporaryAlertView(mode: "comment")                             // 코멘트 모드에서 선택된 텍스트가 없을 때 표시
                }
                
                if mainPDFViewModel.statusStack.isTranslationSelected {
                    if #unavailable(iOS 18.0) {
                        TranslateViewOlderVer()                                     // 번역 모드가 활성화되었을 때 표시
                    } else {
                        if translationManager.selectedText.isEmpty {
                            TemporaryAlertView(mode: "translate")                   // 번역 모드에서 선택된 텍스트가 없을 때 표시
                        } else {
                            TranslateView()
                                .environmentObject(mainPDFViewModel)
                                .environment(translationManager)
                        }
                    }
                }
                    
                if mainPDFViewModel.statusStack.isFigureSelected &&
                    mainPDFViewModel.statusStack.isCaptureSelected &&
                    focusFigureViewModel.isCaptureMode {
                    TemporaryAlertView(mode: "lasso")                               // Lasso 도구가 활성화되어 있고 캡처 모드일 때 표시
                }
                
                if mainPDFViewModel.statusStack.isCollectionSelected &&
                    mainPDFViewModel.statusStack.isCaptureSelected &&
                    focusFigureViewModel.isCaptureMode {
                    TemporaryAlertView(mode: "lasso")
                }
                
                FloatingViewsContainer(geometry: geometry)
                    .environmentObject(floatingViewModel)
                    .environmentObject(focusFigureViewModel)
                
                if mainPDFViewModel.statusStack.isDetailSelected {
                    GeometryReader { gp in
                        ZStack {
                            PDFInfoMenu()
                            .environmentObject(homeViewModel)
                            .environmentObject(mainPDFViewModel)
                            .environmentObject(pdfInfoMenuViewModel)
                            .transition(.opacity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                }
                
                Color.black
                    .opacity(mainPDFViewModel.mainPDFViewAction.opacityConstant)
                    .ignoresSafeArea(edges: .bottom)
                
                if focusFigureViewModel.isEditFigName, let id = focusFigureViewModel.selectedID {
                    EditFigNameView(id: id)
                        .environmentObject(floatingViewModel)
                        .environmentObject(focusFigureViewModel)
                        .zIndex(1)
                }
                
                
                Color.black
                    .opacity(mainPDFViewModel.createMovingFolder ? 0.5 : 0)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationBarHidden(true)
            .onAppear {
                self.floatingViewModel.subscribeToFocusFigureViewModel(focusFigureViewModel)
            }
            .onDisappear {
                self.searchViewModel.removeAllAnnotations()
                PDFSharedData.shared.updatePaperInfo()
                // TODO: 에러 처리 필요
                try? mainPDFViewModel.savePDF(pdfView: mainPDFViewModel.pdfDrawer.pdfView)
                self.focusFigureViewModel.stopTask()
                self.focusFigureViewModel.cancellables.removeAll()
            }
            .gesture(
                mainPDFViewModel.statusStack.isDetailSelected
                ? DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        print("터치 감지됨!")
                        mainPDFViewModel.statusStack.detailOff()
                    }
                : nil
            )
        }
        .overlay {
            switch mainPDFViewModel.mainPDFViewAction {
                // 파일 이름 수정 뷰
            case let .editingPaperTitle(paperInfo):
                RenamePaperTitleView(
                    paperInfo: paperInfo,
                    cancelAction: {
                        self.mainPDFViewModel.renameTitleCancelButtonTapped()
                    },
                    completeAction: { title in
                        self.mainPDFViewModel.renameTitleOKButtonTapped(paperInfo: paperInfo, title: title)
                    }
                )
                // 타이틀 중복 알럿
            case .duplicatedTitleAlert:
                CustomAlert(
                    type: .confirm,
                    mainText: String(localized: "같은 제목의 논문이 이미 존재합니다"),
                    message: String(localized: "다른 제목을 입력해주세요"),
                    width: 350,
                    height: 176,
                    cancelAction: {
                        mainPDFViewModel.mainPDFViewAction = .none
                    },
                    confirmAction: {}
                )
                // 폴더 이동 뷰
            case .movingFolder:
                MoveFolderView(
                    id: PDFSharedData.shared.paperInfo?.folderID,
                    items: PDFSharedData.shared.paperInfo != nil ?
                    [PDFSharedData.shared.paperInfo!] : [],
                    cancelAction: {
                        mainPDFViewModel.mainPDFViewAction = .none
                    },
                    createFolderAction: { folderId in
                        if homeViewModel.depth(of: folderId) < 4 {
                            mainPDFViewModel.mainPDFViewAction = .creatingMovingFolder(folderId)
                        } else {
                            mainPDFViewModel.mainPDFViewAction = .folderDepthAlert
                        }
                    },
                    moveAction: { folderId in
                        if let paperInfo = PDFSharedData.shared.paperInfo {
                            homeViewModel.updatePaperLocation(at: paperInfo.id, folderID: folderId)
                        }
                        
                        mainPDFViewModel.mainPDFViewAction = .none
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: 740, height: 550)
                
            case let .creatingMovingFolder(id):
                FolderView(
                    folder: homeViewModel.folders.first { $0.id == id },
                    cancelAction: {
                        mainPDFViewModel.mainPDFViewAction = .movingFolder
                    },
                    completeAction: { color, title, folder in
                        let text = title.isEmpty ? String(localized: "새 폴더") : title
                        
                        if let folder = folder {
                            homeViewModel.createSubfolder(in: folder.id, title: text, color: color.rawValue)
                        } else {
                            homeViewModel.createSubfolder(in: nil, title: text, color: color.rawValue)
                        }
                        
                        mainPDFViewModel.mainPDFViewAction = .movingFolder
                    }
                )
            case .folderDepthAlert:
                CustomAlert(
                    type: .confirm,
                    mainText: String(localized: "Reazy는 하위 폴더를\n4개까지 제공합니다."),
                    width: 340, height: 163,
                    cancelAction: {
                        mainPDFViewModel.mainPDFViewAction = .movingFolder
                    }
                )
                
            default: EmptyView()
            }
            
            if self.focusFigureViewModel.figureStatus == .loading {
                FigureLoadingView(isOriginal: true)
            } else if self.focusFigureViewModel.focusStatus == .loading {
                FigureLoadingView(isOriginal: false)
            }
            
            if self.focusFigureViewModel.focusStatus == .networkDisconnection {
                ZStack {
                    Color.gray900
                        .opacity(0.4)
                        .ignoresSafeArea()
                    
                    NetworkDisconnectionAlert {
                        focusFigureViewModel.focusStatus = .beforeStart
                    }
                }
            }
        }
        .alert(
            "현재 집중모드가 공사중에 있습니다.",
            isPresented: Binding(
                    get: {
                        mainPDFViewModel.statusStack.isConcentrateSelected
                    },
                    set: { _ in }
                )
        ) {
            Button("확인", role: .cancel) {
                mainPDFViewModel.statusStack.concentrateToggle()
            }
        } message: {
            Text("곧 다가올 업데이트를 기대해주세요!")
        }
        .alert(
            "정말 삭제하시겠습니까?",
            isPresented: mainPDFViewModel.mainPDFViewAction.isDeletePapersAlertPresented,
            presenting: PDFSharedData.shared.paperInfo
        ) { item in
            Button("취소", role: .cancel) {
                // TODO: 취소 액션 연결 필요
                mainPDFViewModel.mainPDFViewAction = .none
            }
            Button("삭제", role: .destructive) {
                homeViewModel.deletePDF(at: item.id)
                mainPDFViewModel.mainPDFViewAction = .none
                navigationCoordinator.pop()
            }
        } message: { _ in
            Text("삭제된 파일은 복구할 수 없습니다.")
        }
    }
}



private struct MainOriginalView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject private var floatingViewModel: FloatingViewModel
    @EnvironmentObject private var focusFigureViewModel: FocusFigureViewModel
    
    @State private var orientation: LayoutOrientation = .horizontal
    
    @State private var dynamicWidth: CGFloat = 0
    @State private var dynamicHeight: CGFloat = 0
    
    let publisher = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
    
    var body: some View {
        Group {
            switch self.orientation {
            case .vertical:
                GeometryReader { geometry in
                    VStack(spacing:0) {
                        ZStack {
                            if floatingViewModel.isPaperViewRight,
                               let splitDetails = floatingViewModel.getSplitDocumentDetails() {
                                VStack(spacing: 0) {
                                    ZStack {
                                        FloatingSplitView(
                                            id: splitDetails.id,
                                            documentID: splitDetails.documentID,
                                            document: splitDetails.document,
                                            head: splitDetails.head,
                                            onSelect: {
                                                withAnimation {
                                                    floatingViewModel.isPaperViewFirst.toggle()
                                                }
                                            },
                                            isVertical: true,
                                            dynamicHeight: $dynamicHeight
                                        )
                                        
                                        VStack(spacing: 0) {
                                            Spacer()
                                            Rectangle()
                                                .frame(height: 8)
                                                .foregroundStyle(.gray550)
                                                .contentShape(Rectangle())
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .frame(width: 44, height: 4)
                                                        .foregroundStyle(.gray200)
                                                        .padding(.vertical, 5)
                                                }
                                                .highPriorityGesture(
                                                    DragGesture()
                                                        .onChanged { value in
                                                            let newHeight = dynamicHeight + value.translation.height
                                                            dynamicHeight = max(geometry.size.height * 2 / 7, min(newHeight, geometry.size.height - 50))
                                                        }
                                                )
                                        }
                                    }
                                    
                                    divider
                                }
                                .frame(height: dynamicHeight)
                            }
                        }
                        .zIndex(1)
                        
                        ZStack {
                            MainView()
                        }
                        
                        ZStack {
                            if floatingViewModel.isPaperViewLeft,
                               let splitDetails = floatingViewModel.getSplitDocumentDetails() {
                                VStack(spacing: 0) {
                                    divider
                                    
                                    ZStack {
                                        FloatingSplitView(
                                            id: splitDetails.id,
                                            documentID: splitDetails.documentID,
                                            document: splitDetails.document,
                                            head: splitDetails.head,
                                            onSelect: {
                                                withAnimation {
                                                    floatingViewModel.isPaperViewFirst.toggle()
                                                }
                                            },
                                            isVertical: true,
                                            dynamicHeight: $dynamicHeight
                                        )
                                        
                                        VStack(spacing: 0) {
                                            Rectangle()
                                                .frame(height: 8)
                                                .foregroundStyle(.gray550)
                                                .contentShape(Rectangle())
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 2)
                                                        .frame(width: 44, height: 4)
                                                        .foregroundStyle(.gray200)
                                                        .padding(.vertical, 5)
                                                }
                                                .highPriorityGesture(
                                                    DragGesture()
                                                        .onChanged { value in
                                                            let newHeight = dynamicHeight - value.translation.height
                                                            dynamicHeight = max(geometry.size.height * 2 / 7, min(newHeight, geometry.size.height - 50))
                                                        }
                                                )
                                            Spacer()
                                        }
                                    }
                                }
                                .frame(height: dynamicHeight)
                            }
                        }
                        .zIndex(1)
                    }
                    .onAppear {
                        dynamicHeight = geometry.size.height / 2
                    }
                    .onChange(of: geometry.size) {
                        dynamicHeight = geometry.size.height / 2
                    }
                }
            case .horizontal:
                GeometryReader { geometry in
                    HStack(spacing:0) {
                        if floatingViewModel.isPaperViewRight,
                           let splitDetails = floatingViewModel.getSplitDocumentDetails() {
                            HStack(spacing: 0) {
                                ZStack {
                                    FloatingSplitView(
                                        id: splitDetails.id,
                                        documentID: splitDetails.documentID,
                                        document: splitDetails.document,
                                        head: splitDetails.head,
                                        onSelect: {
                                            withAnimation {
                                                floatingViewModel.isPaperViewFirst.toggle()
                                            }
                                        },
                                        isVertical: false,
                                        dynamicHeight: $dynamicHeight
                                    )
                                    
                                    HStack(spacing: 0) {
                                        Spacer()
                                        Rectangle()
                                            .frame(width: 8)
                                            .foregroundStyle(.gray550)
                                            .contentShape(Rectangle())
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .frame(width: 4, height: 44)
                                                    .foregroundStyle(.gray200)
                                                    .padding(.horizontal, 5)
                                            }
                                            .highPriorityGesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        let newWidth = dynamicWidth + value.translation.width
                                                        dynamicWidth = max(geometry.size.width * 2 / 7, min(newWidth, geometry.size.width - 50))
                                                    }
                                            )
                                    }
                                }
                                
                                divider
                            }
                            .frame(width: dynamicWidth)
                        }
                        
                        MainView()
                        
                        if floatingViewModel.isPaperViewLeft,
                           let splitDetails = floatingViewModel.getSplitDocumentDetails() {
                            HStack(spacing: 0) {
                                divider
                                
                                ZStack {
                                    FloatingSplitView(
                                        id: splitDetails.id,
                                        documentID: splitDetails.documentID,
                                        document: splitDetails.document,
                                        head: splitDetails.head,
                                        onSelect: {
                                            withAnimation {
                                                floatingViewModel.isPaperViewFirst.toggle()
                                            }
                                        },
                                        isVertical: false,
                                        dynamicHeight: $dynamicHeight
                                    )
                                    
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .frame(width: 8)
                                            .foregroundStyle(.gray550)
                                            .contentShape(Rectangle())
                                            .overlay {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .frame(width: 4, height: 44)
                                                    .foregroundStyle(.gray200)
                                                    .padding(.horizontal, 5)
                                            }
                                            .highPriorityGesture(
                                                DragGesture()
                                                    .onChanged { value in
                                                        let newWidth = dynamicWidth - value.translation.width
                                                        dynamicWidth = max(geometry.size.width * 2 / 7, min(newWidth, geometry.size.width - 50))
                                                    }
                                            )
                                        Spacer()
                                    }
                                }
                            }
                            .frame(width: dynamicWidth)
                        }
                    }
                    .onAppear {
                        dynamicWidth = geometry.size.width / 2
                    }
                    .onChange(of: geometry.size) {
                        dynamicWidth = geometry.size.width / 2
                    }
                }
            }
        }
        .onAppear {
            getOrientationFromFace()
        }
        .onReceive(publisher) { _ in
            switch UIDevice.current.orientation {
            case .portrait, .portraitUpsideDown:
                self.orientation = .vertical
            case .landscapeLeft, .landscapeRight:
                self.orientation = .horizontal
            case .faceUp, .faceDown:
               self.getOrientationFromFace()
            default:
                break
            }
        }
    }
    
    private var divider: some View {
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
    
    private func getOrientationFromFace() {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let sceneDelegate = scene as? UIWindowScene else { return }
        
        switch sceneDelegate.interfaceOrientation {
        case .portrait, .portraitUpsideDown:
            self.orientation = .vertical
        case .landscapeLeft, .landscapeRight:
            self.orientation = .horizontal
        default:
            self.orientation =  .horizontal
        }
    }
}


private struct MainView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject private var focusFigureViewModel: FocusFigureViewModel
    
    var body: some View {
        ZStack {
            OriginalView()
            
            // MARK: 집중모드 임시 차단
            /*
            if isReadMode {
                ConcentrateView()
            }
             */
        }
    }
}

private struct FigureLoadingView: View {
    @State private var timer: Timer?
    @State private var loadingTextFlag: Bool = false
    
    let isOriginal: Bool
    
    var body: some View {
        ZStack {
            Color.gray900
                .opacity(0.4)
                .ignoresSafeArea()
            
            RoundedRectangle(cornerRadius: 16)
                .frame(width: 306, height: 128)
                .foregroundStyle(.white)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.primary1)
                    .frame(width: 16)
                
                if isOriginal {
                    Text( self.loadingTextFlag ? "Figure 추출은 10초 ~ 20초 정도 소요됩니다" : "Figure와 Table을 불러오는 중입니다" )
                        .reazyFont(.body1)
                        .foregroundStyle(.primary1)
                } else {
                    Text( self.loadingTextFlag ? "집중모드를 활성화 중입니다" : "집중모드는 논문을 한 단으로\n정렬하는 읽기전용 모드입니다" )
                        .reazyFont(.body1)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.primary1)
                }
            }
        }
        .onAppear {
            self.timer = .scheduledTimer(withTimeInterval: 4, repeats: true) { _ in
                self.loadingTextFlag.toggle()
            }
        }
        .onDisappear {
            self.timer?.invalidate()
        }
    }
}

private struct NetworkDisconnectionAlert: View {
    let completeAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("집중모드 활성화를 위해\n네트워크 연결이 필요합니다")
                .reazyFont(.button1)
                .foregroundStyle(.gray900)
                .multilineTextAlignment(.center)
                .padding(.top, 36)
                .padding(.horizontal, 30)
            
            Spacer()
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray400)
            
            Button {
                completeAction()
            } label: {
                Text("취소")
                    .reazyFont(.h3)
                    .foregroundStyle(.primary1)
                    .frame(width: 300, height: 52)
            }

        }
        .frame(width: 340, height: 163)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
        )
    }
}



extension View {
    func unfocusKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
