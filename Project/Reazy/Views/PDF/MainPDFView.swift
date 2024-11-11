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
    
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject private var pdfFileManager: PDFFileManager
    
    
    @StateObject public var mainPDFViewModel: MainPDFViewModel
    @StateObject private var floatingViewModel: FloatingViewModel = .init()
    @StateObject public var commentViewModel: CommentViewModel
    
    @State private var selectedButton: WriteButton? = nil
    @State private var selectedColor: HighlightColors = .yellow
    
    @State private var selectedIndex: Int = 0
    @State private var isReadModeFirstSelected: Bool = false
    
    @State private var isFigSelected: Bool = false
    @State private var isSearchSelected: Bool = false
    @State private var isVertical = false
    @State private var isModifyTitlePresented: Bool = false
    @State private var titleText: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Divider()
                        .foregroundStyle(Color(hex: "CCCEE1"))
                    
                    ZStack {
                        HStack(spacing: 0) {
                            Button(action: {
                                if selectedIndex == 1 {
                                    selectedIndex = 0
                                } else {
                                    selectedIndex = 1
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(selectedIndex == 1 ? .primary1 : .clear)
                                    .overlay (
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.clear)
                                                .frame(width: 26, height: 26)
                                            
                                            Image(systemName: "list.bullet")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(selectedIndex == 1 ? .gray100 : .gray800)
                                                .frame(width: 18)
                                        }
                                    )
                            }
                            .padding(.trailing, 36)
                            
                            Button(action: {
                                if selectedIndex == 2 {
                                    selectedIndex = 0
                                } else {
                                    selectedIndex = 2
                                }
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                    .foregroundStyle(selectedIndex == 2 ? .primary1 : .clear)
                                    .overlay (
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.clear)
                                                .frame(width: 26, height: 26)
                                            
                                            Image(systemName: "rectangle.grid.1x2")
                                                .resizable()
                                                .scaledToFit()
                                                .foregroundStyle(selectedIndex == 2 ? .gray100 : .gray800)
                                                .frame(width: 18)
                                        }
                                    )
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                isFigSelected.toggle()
                            }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: 26, height: 26)
                                // MARK: - 부리꺼 : 색상 적용 필요
                                    .foregroundStyle(isFigSelected ? Color(hex: "5F5DAA") : .clear)
                                    .overlay (
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.clear)
                                                .frame(width: 26, height: 26)
                                            Text("Fig")
                                                .font(.system(size: 14))
                                                .foregroundStyle(isFigSelected ? .gray100 : .gray800)
                                        }
                                    )
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 22)
                        .background(.primary3)
                        
                            HStack(spacing: 0) {
                                Spacer()
                                
                                ForEach(WriteButton.allCases, id: \.self) { btn in
                                    // 조건부 Padding값 조정
                                    let trailingPadding: CGFloat = {
                                        if selectedButton == .highlight && btn == .highlight {
                                            return .zero
                                        } else if btn == .translate {
                                            return .zero
                                        } else {
                                            return 32
                                        }
                                    }()
                                    
                                    // [Comment], [Highlight], [Pencil], [Eraser], [Translate] 버튼
                                    WriteViewButton(button: $selectedButton, HighlightColors: $selectedColor, buttonOwner: btn) {
                                        // MARK: - 작성 관련 버튼 action 입력
                                        /// 위의 다섯 개 버튼의 action 로직은 이곳에 입력해 주세요
                                        if selectedButton == btn {
                                            selectedButton = nil
                                            mainPDFViewModel.toolMode = .none
                                        } else {
                                            selectedButton = btn
                                        }
                                        
                                        switch selectedButton {
                                        case .translate:
                                            NotificationCenter.default.post(name: .PDFViewSelectionChanged, object: nil)
                                            mainPDFViewModel.toolMode = .translate
                                            
                                        case .pencil:
                                            mainPDFViewModel.toolMode = .pencil
                                            
                                        case .eraser:
                                            mainPDFViewModel.toolMode = .eraser
                                            
                                        case .highlight:
                                            mainPDFViewModel.toolMode = .highlight
                                            
                                        case .comment:
                                            mainPDFViewModel.toolMode = .comment
                                            
                                        default:
                                            // 전체 비활성화
                                            mainPDFViewModel.toolMode = .none
                                        }
                                    }
                                    .padding(.trailing, trailingPadding)
                                    
                                    // Highlight 버튼이 선택될 경우 색상을 선택
                                    if selectedButton == .highlight && btn == .highlight {
                                        highlightColorSelector()
                                    }
                                }
                                
                                Spacer()
                            }
                            .background(.clear)
                        
                    }
                    
                    Divider()
                        .foregroundStyle(Color(hex: "CCCEE1"))
                    
                    GeometryReader { geometry in
                        ZStack {
                                ZStack {
                                    if isVertical {
                                        splitLayout(for: .vertical)
                                    } else {
                                        splitLayout(for: .horizontal)
                                    }
                            }
                            
                            HStack(spacing: 0){
                                if selectedIndex == 1 {
                                    TableView()
                                        .environmentObject(mainPDFViewModel)
                                        .background(.white)
                                        .frame(width: geometry.size.width * 0.22)
                                    
                                    Rectangle()
                                        .frame(width: 1)
                                        .foregroundStyle(Color(hex: "CCCEE1"))
                                } else if selectedIndex == 2 {
                                    PageView()
                                        .environmentObject(mainPDFViewModel)
                                        .background(.white)
                                        .frame(width: geometry.size.width * 0.22)
                                    
                                    Rectangle()
                                        .frame(width: 1)
                                        .foregroundStyle(Color(hex: "CCCEE1"))
                                } else {
                                    EmptyView()
                                }
                                
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
                                    .background(.white)
                                    .frame(width: geometry.size.width * 0.22)
                                }
                            }
                        }
                        .ignoresSafeArea()
                    }
                }
                .customNavigationBar(
                    centerView: {
                        HStack(spacing: 5) {
                            Text(mainPDFViewModel.paperInfo.title)
                                .reazyFont(.h3)
                                .foregroundStyle(.gray800)
                                .lineLimit(1)
                            
                            Button {
                                self.isModifyTitlePresented.toggle()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.clear)
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray800)
                                }
                            }
                            .padding(.leading, 0)
                            .popover(isPresented: $isModifyTitlePresented) {
                                ZStack {
                                    Color.gray200
                                        .scaleEffect(1.5)
                                    
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(.gray100)
                                            .frame(width: 400, height: 52)
                                        
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(lineWidth: 1)
                                            .foregroundStyle(.gray400)
                                            .frame(width: 400, height: 52)
                                        
                                        HStack(spacing: 0) {
                                            TextField("제목을 입력하세요", text: $titleText)
                                                .reazyFont(.body2)
                                                .foregroundStyle(.gray900)
                                                .padding(EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 0))
                                            
                                            Button {
                                                self.titleText.removeAll()
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.gray600)
                                            }
                                            .padding(.trailing, 8)
                                            
                                        }
                                        .frame(width: 400, height: 52)
                                        
                                    }
                                    .padding(.vertical, 15)
                                    .padding(.horizontal, 15)
                                }
                                .onAppear {
                                    self.titleText = mainPDFViewModel.paperInfo.title
                                }
                                .onDisappear {
                                    if !self.titleText.isEmpty {
                                        let id = self.mainPDFViewModel.paperInfo.id
                                        self.pdfFileManager.updateTitle(at: id, title: self.titleText)
                                        self.mainPDFViewModel.paperInfo.title = self.titleText
                                    }
                                }
                            }
                            
                        }
                        .frame(width: isVertical ? 383 : 567)

                    },
                    leftView: {
                        HStack(spacing: 0) {
                            Button(action: {
                                navigationCoordinator.pop()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.clear)
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: "chevron.left")
                                        .foregroundStyle(.gray800)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(.trailing, 10)
                            
                            Button(action: {
                                self.isSearchSelected.toggle()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.clear)
                                        .frame(width: 26, height: 26)
                                    
                                    Image(systemName: "magnifyingglass")
                                        .foregroundStyle(.gray800)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                    },
                    rightView: {
                        EmptyView()
                    }
                )
                .overlay {
                    OverlaySearchView(isSearchSelected: self.$isSearchSelected)
                        .environmentObject(mainPDFViewModel)
                        .animation(.spring(.bouncy), value: self.isSearchSelected)
                }
                
                // MARK: - Floating 뷰
                FloatingViewsContainer(geometry: geometry)
                    .environmentObject(floatingViewModel)
            }
            .onAppear {
                updateOrientation(with: geometry)
            }
            .onDisappear {
                mainPDFViewModel.savePDF(pdfView: mainPDFViewModel.pdfDrawer.pdfView)
                // TODO: - [브리] commentViewModel에 있는 comments랑 buttonGroup 배열 두 개 저장하는 거 여기서
            }
            .onChange(of: geometry.size) {
                updateOrientation(with: geometry)
            }
            .onChange(of: self.mainPDFViewModel.figureStatus) { _, newValue in
                // 다운로드가 완료된 경우 isFigureSaved 값 변경
                if newValue == .complete {
                    let id = self.mainPDFViewModel.paperInfo.id
                    self.pdfFileManager.updateIsFigureSaved(at: id, isFigureSaved: true)
                }
            }
            .statusBarHidden()
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
            .environmentObject(mainPDFViewModel)
            .environmentObject(floatingViewModel)
            
            divider(for: orientation)
        }
        
        ZStack {
            OriginalView()
                .environmentObject(mainPDFViewModel)
                .environmentObject(floatingViewModel)
                .environmentObject(commentViewModel)
            // 18 미만 버전에서 번역 모드 on 일 때 말풍선 띄우기
            if #unavailable(iOS 18.0) {
                if mainPDFViewModel.toolMode == .translate {
                    BubbleViewOlderVer()
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
            .environmentObject(mainPDFViewModel)
            .environmentObject(floatingViewModel)
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
    
    @ViewBuilder
    private func highlightColorSelector() -> some View {
        Rectangle()
            .frame(width: 1, height: 19)
            .foregroundStyle(.primary4)
            .padding(.leading, 24)
            .padding(.trailing, 17)
        
        ForEach(HighlightColors.allCases, id: \.self) { color in
            ColorButton(button: $selectedColor, buttonOwner: color) {
                // MARK: - 펜 색상 변경 action 입력
                /// 펜 색상을 변경할 경우, 변경된 색상을 입력하는 로직은 여기에 추가
                selectedColor = color
                mainPDFViewModel.selectedHighlightColor = color
            }
            .padding(.trailing, color == .blue ? .zero : 10)
        }
        
        Rectangle()
            .frame(width: 1, height: 19)
            .foregroundStyle(.primary4)
            .padding(.leading, 24)
            .padding(.trailing, 17)
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

