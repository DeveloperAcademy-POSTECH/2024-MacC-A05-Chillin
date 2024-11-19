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
    
    
    @StateObject public var mainPDFViewModel: MainPDFViewModel
    @StateObject private var floatingViewModel: FloatingViewModel = .init()
    @StateObject public var commentViewModel: CommentViewModel
    @StateObject public var focusFigureViewModel: FocusFigureViewModel
    @StateObject public var pageListViewModel: PageListViewModel
    @StateObject public var searchViewModel: SearchViewModel
    @StateObject public var indexViewModel: IndexViewModel
    
    @State private var selectedButton: Buttons? = nil
    
    @State private var selectedIndex: Int = 0
    @State private var isReadModeFirstSelected: Bool = false
    
    @State private var isListSelected: Bool = false
    @State private var isFigSelected: Bool = false
    @State private var isSearchSelected: Bool = false
    @State private var isReadMode: Bool = false
    
    @State private var isVertical = false
    @State private var isModifyTitlePresented: Bool = false // 타이틀 바꿀 때 활용하는 Bool값
    @State private var titleText: String = ""
    
    @State private var isMenuSelected: Bool = false
    @State private var menuButtonPosition: CGPoint = .zero
    
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
                                            .font(.system(size: 14))
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
                                        Image(systemName: "list.bullet")
                                            .font(.system(size: 14))
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
                                    .overlay {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 16))
                                            .foregroundStyle( isSearchSelected ? .gray100 : .gray800 )
                                    }
                            }
                            
                            Rectangle()
                                .frame(width: 1.2, height: 16)
                                .foregroundStyle(.primary4)
                                .padding(.horizontal, 16)
                            
                            Button(action: {
                                isReadMode.toggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .foregroundStyle( isReadMode ? .primary1 : .clear )
                                    .frame(width: 26, height: 26)
                                    .overlay {
                                        Image(systemName: "text.justify")
                                            .font(.system(size: 14))
                                            .foregroundStyle( isReadMode ? .gray100 : .gray800 )
                                    }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isFigSelected.toggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                // MARK: - 부리꺼 : 색상 적용 필요
                                    .foregroundStyle(isFigSelected ? .primary1 : .clear)
                                    .overlay (
                                        Text("Fig")
                                            .font(.system(size: 14))
                                            .foregroundStyle( isFigSelected ? .gray100 : .gray800 )
                                    )
                            }
                            .padding(.trailing, 24)
                            
                            Button(action: {
                                isMenuSelected.toggle()
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
                                ButtonsView(button: $selectedButton, selectedButton: btn) {
                                    if selectedButton == btn {
                                        selectedButton = nil
                                        mainPDFViewModel.toolMode = .none
                                    } else {
                                        selectedButton = btn
                                    }
                                    
                                    
                                    switch selectedButton {
                                    case .drawing:
                                        mainPDFViewModel.toolMode = .drawing
                                    case .comment:
                                        mainPDFViewModel.toolMode = .comment
                                    case .translate:
                                        NotificationCenter.default.post(name: .PDFViewSelectionChanged, object: nil)
                                        mainPDFViewModel.toolMode = .translate
                                    case .lasso:
                                        // TODO: - toolMode에 올가미 추가
                                        print("올가미 모드 선택")
                                    default:
                                        mainPDFViewModel.toolMode = .none
                                    }
                                }
                                .padding(.trailing, btn == .lasso ? 0 : 30 )
                            }
                            
                            Spacer()
                        }
                        
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 11)
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
                                        MenuView()
                                            .environmentObject(mainPDFViewModel)
                                            .environmentObject(indexViewModel)
                                            .environmentObject(pageListViewModel)
                                            .frame(width: 252)
                                            .background(.gray100)
                                            .transition(.move(edge: .leading))
                                    }
                                    
                                    if isSearchSelected {
                                        // TODO: - [무니] SearchView 추가 필요
                                    }
                                    
                                }
                                
                                
                                ZStack {
                                    if isVertical {
                                        splitLayout(for: .vertical)
                                    } else {
                                        splitLayout(for: .horizontal)
                                    }
                                }
                            }
                            .animation(.easeInOut(duration: 0.3), value: isListSelected)
                            
                            HStack(spacing: 0) {
                                Spacer()
                                
                                if isFigSelected && !floatingViewModel.splitMode {
                                    Rectangle()
                                        .frame(width: 1)
                                        .foregroundStyle(Color(hex: "CCCEE1"))
                                    
                                    FigureView(onSelect: { documentID, document, head in
                                        floatingViewModel.toggleSelection(for: documentID, document: document, head: head)
                                    })
                                    .environmentObject(mainPDFViewModel)
                                    .environmentObject(floatingViewModel)
                                    .environmentObject(focusFigureViewModel)
                                    .background(.white)
                                    .frame(width: geometry.size.width * 0.22)
                                }
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
                
                if mainPDFViewModel.toolMode == .drawing {
                    // TODO: -[브리] 위치 이동 필요
                    HStack(spacing: 0) {
                        DrawingView()
                            .environmentObject(mainPDFViewModel)
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.gray100)
                            }
                            .padding(.leading, 24)
                        
                        Spacer()
                    }
                }
                
                // Menu 버튼 뷰
                if isMenuSelected {
                    PDFInfoMenu()
                        .position(x: menuButtonPosition.x - 130 , y: menuButtonPosition.y + 230 )
                        .transition(.move(edge: .top))
                }
            }
            
            // MARK: - Floating 뷰
            FloatingViewsContainer(geometry: geometry)
                .environmentObject(floatingViewModel)
            
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
                .statusBarHidden()
        }
    }
    
    @ViewBuilder
    private func mainView(isReadMode: Bool) -> some View {
        if isReadMode {
            // TODO: - [무니] 집중모드 수정
            ConcentrateView()
                .environmentObject(mainPDFViewModel)
        } else {
            OriginalView()
                .environmentObject(mainPDFViewModel)
                .environmentObject(floatingViewModel)
                .environmentObject(commentViewModel)
                .environmentObject(focusFigureViewModel)
                .environmentObject(pageListViewModel)
                .environmentObject(searchViewModel)
                .environmentObject(indexViewModel)
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
        if isSearchSelected {
            HStack {
                VStack(spacing: 0) {
                    SearchView()
                        .padding(EdgeInsets(top: 60, leading: 20, bottom: 0, trailing: 0))
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

