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
    
    @StateObject public var mainPDFViewModel: MainPDFViewModel
    @StateObject private var floatingViewModel: FloatingViewModel = .init()
    
    @State private var selectedButton: WriteButton? = nil
    @State private var selectedColor: HighlightColors = .yellow
    
    // 모드 구분
    @State private var selectedMode = "원문 모드"
    var mode = ["원문 모드", "집중 모드"]
    @Namespace private var animationNamespace
    
    @State private var selectedIndex: Int = 0
    @State private var isReadModeFirstSelected: Bool = false
    
    @State private var isFigSelected: Bool = false
    @State private var isSearchSelected: Bool = false
    @State private var isVertical = false
    
    
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
                                        Image(systemName: "list.bullet")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(selectedIndex == 1 ? .gray100 : .gray800)
                                            .frame(width: 18)
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
                                        Image(systemName: "rectangle.grid.1x2")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(selectedIndex == 2 ? .gray100 : .gray800)
                                            .frame(width: 18)
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
                                        Text("Fig")
                                            .font(.system(size: 14))
                                            .foregroundStyle(isFigSelected ? .gray100 : .gray800)
                                    )
                            }
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 22)
                        .background(.primary3)
                        
                        if selectedMode == "원문 모드" {
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
                    }
                    
                    Divider()
                        .foregroundStyle(Color(hex: "CCCEE1"))
                    
                    GeometryReader { geometry in
                        ZStack {
                            if selectedMode == "원문 모드" || selectedMode == "집중 모드" {
                                ZStack {
                                    if isVertical {
                                        splitLayout(for: .vertical)
                                    } else {
                                        splitLayout(for: .horizontal)
                                    }
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
                        .onChange(of: selectedMode) {
                            // 원문 <-> 집중 바뀔 때마다 버튼 5개 상태 초기화
                            selectedButton = nil
                        }
                        .ignoresSafeArea()
                    }
                }
                .customNavigationBar(
                    centerView: {
                        Text(mainPDFViewModel.paperInfo.title)
                            .reazyFont(.h3)
                            .foregroundStyle(.gray800)
                            .frame(width: isVertical ? 383 : 567)
                            .lineLimit(1)
                    },
                    leftView: {
                        HStack(spacing: 0) {
                            Button(action: {
                                navigationCoordinator.pop()
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundStyle(.gray800)
                                    .font(.system(size: 14))
                            }
                            .padding(.trailing, 29)
                            Button(action: {
                                self.isSearchSelected.toggle()
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.gray800)
                                    .font(.system(size: 16))
                            }
                        }
                    },
                    rightView: {
                        HStack(spacing: 0) {
                            // Custom segmented picker
                            HStack(spacing: 0) {
                                ForEach(mode, id: \.self) { item in
                                    Text(item)
                                        .reazyFont(selectedMode == item ? .button4 : .button5)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 5)
                                        .background(
                                            ZStack {
                                                if selectedMode == item {
                                                    RoundedRectangle(cornerRadius: 7)
                                                        .fill(.gray100)
                                                        .matchedGeometryEffect(id: "underline", in: animationNamespace)
                                                }
                                            }
                                        )
                                        .foregroundColor(selectedMode == item ? .gray900 : .gray600)
                                        .onTapGesture {
                                            withAnimation(.spring()) {
                                                selectedMode = item
                                            }
                                        }
                                        .padding(.horizontal, 2)
                                        .padding(.vertical, 2)
                                }
                            }
                            .background(.gray500)
                            .cornerRadius(9)
                        }
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
            .onChange(of: geometry.size) {
                updateOrientation(with: geometry)
            }
        }
    }
    
    @ViewBuilder
    private func mainView(for mode: String) -> some View {
        if mode == "원문 모드" {
            ZStack {
                OriginalView()
                    .environmentObject(mainPDFViewModel)
                    .environmentObject(floatingViewModel)
                // 18 미만 버전에서 번역 모드 on 일 때 말풍선 띄우기
                if #unavailable(iOS 18.0) {
                    if mainPDFViewModel.toolMode == .translate {
                        BubbleViewOlderVer()
                    }
                }
            }
        } else if mode == "집중 모드" {
            ConcentrateView()
                .environmentObject(mainPDFViewModel)
                .onAppear {
                    if !isReadModeFirstSelected {
                        selectedIndex = 1
                        isFigSelected = true
                        isReadModeFirstSelected = true
                    }
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
        
        mainView(for: selectedMode)
        
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
            .padding(.trailing, color == .blue ? .zero : 18)
        }
        
        Rectangle()
            .frame(width: 1, height: 19)
            .foregroundStyle(.primary4)
            .padding(.leading, 24)
            .padding(.trailing, 17)
    }
}

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
