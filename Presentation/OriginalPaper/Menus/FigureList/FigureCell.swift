//
//  FigureCell.swift
//  Reazy
//
//  Created by 유지수 on 10/15/24.
//


import SwiftUI
import PDFKit
import UniformTypeIdentifiers


// MARK: - Lucid : FigureView 커스텀 리스트 셀
struct PDFKitView: UIViewRepresentable {
    
    let document: PDFDocument
    var isScrollEnabled: Bool
    
    // PDFView 생성 후 반환
    func makeUIView(context: Context) -> PDFView {
        
        let pdfView = PDFView()
        
        pdfView.autoScales = true       // PDF가 뷰에 맞춰서 스케일 조정
        pdfView.document = document
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.displayMode = .singlePageContinuous
        pdfView.pageShadowsEnabled = false
        pdfView.backgroundColor = .white
        
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.isScrollEnabled = isScrollEnabled
        }
        
        return pdfView
    }
    
    // 업데이트 메서드 (필요에 따라 사용)
    func updateUIView(_ uiView: PDFView, context: Context) {
        // 스크롤 활성화 상태 업데이트
        if let scrollView = uiView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.isScrollEnabled = isScrollEnabled
        }
    }
}


struct FigureCell: View {
    
    @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
//    @ObservedObject var observableDocument: ObservableDocument
//    init(documentID: String, document: PDFDocument, head: String, isSelected: Binding<Bool>, viewOffset: Binding<CGSize>, viewWidth: Binding<CGFloat>) {
//        _observableDocument = ObservedObject(wrappedValue: ObservableDocument(document: document))
//    }
    
    let id: UUID
    let onSelect: (String, PDFDocument, String) -> Void
    
    @State private var aspectRatio: CGFloat = 1.0
    
    @State private var newFigName: String = ""
    
    @State private var isDeleteFigAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack  {
                let index = focusFigureViewModel.figures.firstIndex(where: { $0.uuid == id }) ?? 0
                
                if let document = focusFigureViewModel.setFigureDocument(for: index) {
                    if let page = document.page(at: 0) {
                        let pageRect = page.bounds(for: .mediaBox)
                        let aspectRatio = pageRect.width / pageRect.height
                        let head = focusFigureViewModel.figures[index].head
                        let documentID = "figure-\(index)"
                        
                        PDFKitView(document: document, isScrollEnabled: false)
                            .edgesIgnoringSafeArea(.all)                    // 전체 화면에 맞추기
                            .padding(8)
                            .aspectRatio(aspectRatio, contentMode: .fit)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    if floatingViewModel.selectedFigureCellID != documentID {
                                        onSelect(documentID, document, head)
                                    }
                                }
                            )
                        
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(floatingViewModel.isFigureSelected(documentID: documentID) ? .primary1 : .primary3, lineWidth: floatingViewModel.isFigureSelected(documentID: documentID) ? 1.5 : 1)
                        
                        FigureMenu(
                            newFigName: $newFigName,
                            id: id,
                            isDeleteFigAlert: $isDeleteFigAlert
                        )
                            // Fig 삭제 Alert
                            .alert(isPresented: $isDeleteFigAlert) {
                                Alert(
                                    title: Text("\(focusFigureViewModel.figures[index].head)를 삭제하시겠습니까?"),
                                    message: Text("삭제된 항목은 복구할 수 없습니다."),
                                    primaryButton: .cancel(Text("취소"), action: {
                                        print("Cancel Delete")
                                    }),
                                    secondaryButton: .destructive(Text("삭제"), action: {
                                        focusFigureViewModel.figures.remove(at: index)
                                        print("Delete Fig")
                                    })
                                )
                            }
                        
                        if floatingViewModel.isSaveImgAlert {
                            VStack {
                                Text("사진 앱에 저장되었습니다")
                                    .padding()
                                    .frame(width: 190, height: 40)
                                    .reazyFont(.h3)
                                    .background(Color.gray300)
                                    .foregroundStyle(.gray800)
                                    .cornerRadius(12)
                                    .transition(.opacity)                       // 부드러운 전환 효과
                                    .zIndex(1)                                  // ZStack에서의 순서 조정
                            }
                        }
                    }
                } else {
                    Text("pdf 로드 실패 ")
                }
            }
            .padding(.bottom, 10)
            
            Text(focusFigureViewModel.figures.first(where: { $0.uuid == id})?.head ?? "")
                .reazyFont(.body3)
                .foregroundStyle(.gray800)
        }
    }
}
