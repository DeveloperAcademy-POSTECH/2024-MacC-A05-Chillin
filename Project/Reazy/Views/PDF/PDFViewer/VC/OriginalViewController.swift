//
//  MainPDFViewController.swift
//  Reazy
//
//  Created by 문인범 on 10/17/24.
//

import SwiftUI
import UIKit
import PDFKit
import Combine

/**
 원문 모드 ViewController
 */

class PDFContext: ObservableObject {
    @Published var mainPDFView: PDFView?
}

final class OriginalViewController: UIViewController {
    @ObservedObject var pdfContext = PDFContext()
    
    let viewModel: MainPDFViewModel
    let commentViewModel: CommentViewModel
    
    var cancellable: Set<AnyCancellable> = []
    var selectionWorkItem: DispatchWorkItem?
    
    let mainPDFView: PDFView = {
        let view = PDFView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .gray200
        view.autoScales = false
        view.pageShadowsEnabled = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pdfContext.mainPDFView = mainPDFView
        self.setUI()
        self.setData()
        self.setBinding()
        
        // annotation 버튼 클릭시 제스처
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleAnnotationTap(_:)))
        tapGesture.delegate = self
        mainPDFView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        viewModel.goToPage(at: viewModel.changedPageNumber)
    }
    
    init(viewModel: MainPDFViewModel, commentViewModel: CommentViewModel) {
        self.viewModel = viewModel
        self.commentViewModel = commentViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 제스처
    @objc func handleAnnotationTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mainPDFView)
        
        guard let page = mainPDFView.page(for: location, nearest: true) else { return }
        let pageLocation = mainPDFView.convert(location, to: page)
        
        /// 해당 위치에 Annotation이 있는지 확인
        if let tappedAnnotation = page.annotation(at: pageLocation) {
            print("found annotation")
            
            if let commentIDString = tappedAnnotation.contents,
               let commentID = UUID(uuidString: commentIDString),
               let tappedComment = commentViewModel.comments.first(where: { $0.id == commentID }) {
                
                print(tappedComment)
                viewModel.isCommentTapped = true
                viewModel.commentTappedPosition = tappedComment.position
                
            } else {
                print("No match comment annotation")
            }
        }
    }
}

// MARK: - 초기 설정
extension OriginalViewController {
    /// UI 설정
    private func setUI() {
        self.view.addSubview(self.mainPDFView)
        NSLayoutConstraint.activate([
            self.mainPDFView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mainPDFView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.mainPDFView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.mainPDFView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])
    }
    
    /// ViewModel 설정
    private func setData() {
        self.viewModel.setPDFDocument(url: Bundle.main.url(forResource: "engPD5", withExtension: "pdf")!)
        self.mainPDFView.document = self.viewModel.document
        
        // 집중모드 데이터 패치
        self.viewModel.fetchFocusAnnotations()
        
        // 썸네일 이미지 패치
        self.viewModel.fetchThumbnailImage()
    }
    
    /// 텍스트 선택 해제
    private func cleanTextSelection() {
        self.mainPDFView.currentSelection = nil
    }
    
    /// 데이터 Binding
    private func setBinding() {
        self.viewModel.$selectedDestination
            .sink { [weak self] destination in
                guard let page = destination?.page else { return }
                self?.mainPDFView.go(to: page)
            }
            .store(in: &self.cancellable)
        
        NotificationCenter.default.publisher(for: .PDFViewPageChanged)
            .sink { [weak self] _ in
                guard let page = self?.mainPDFView.currentPage else { return }
                guard let num = self?.viewModel.document?.index(for: page) else { return }
                DispatchQueue.main.async {
                    self?.viewModel.changedPageNumber = num
                }
            }
            .store(in: &self.cancellable)
        
        // 현재 드래그된 텍스트 가져오는 함수
        NotificationCenter.default.publisher(for: .PDFViewSelectionChanged)
            .sink { [weak self] _ in
                guard let self = self else { return }
                guard let selection = self.mainPDFView.currentSelection else {
                    // 선택된 텍스트가 없을 때 특정 액션
                    self.viewModel.selectedText = "" // 선택된 텍스트 초기화
                    self.viewModel.bubbleViewVisible = false // 말풍선 뷰 숨김
                    return
                }
                
                self.selectionWorkItem?.cancel()
                
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    if let page = selection.pages.first {
                        
                        // PDFSelection의 bounds 추출(CGRect)
                        let bound = selection.bounds(for: page)
                        let convertedBounds = self.mainPDFView.convert(bound, from: page)
                        
                        //comment position 설정
                        let commentPosition = CGPoint(
                            x: convertedBounds.midX,
                            y: convertedBounds.maxY + 50
                        )
                        
                        // 선택된 텍스트 가져오기
                        let selectedText = selection.string ?? ""
                        
                        // PDFPage의 좌표를 PDFView의 좌표로 변환
                        let pagePosition = self.mainPDFView.convert(bound, from: page)
                        
                        // PDFView의 좌표를 Screen의 좌표로 변환
                        let screenPosition = self.mainPDFView.convert(pagePosition, to: nil)
                        
                        DispatchQueue.main.async {
                            // ViewModel에 선택된 텍스트와 위치 업데이트
                            self.viewModel.selectedText = selectedText
                            self.viewModel.bubbleViewPosition = screenPosition // 위치 업데이트
                            self.viewModel.bubbleViewVisible = !selectedText.isEmpty // 텍스트가 있을 때만 보여줌
                            
                            self.viewModel.selection = selection
                            self.viewModel.commentPosition = commentPosition
                        }
                    }
                }
                
                // 텍스트 선택 후 딜레이
                self.selectionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
            }
            .store(in: &self.cancellable)
        
        // 저장하면 currentSelection 해제
        self.viewModel.$isCommentSaved
            .sink { [weak self] isCommentSaved in
                if isCommentSaved {
                    self?.cleanTextSelection()
                }
            }
            .store(in: &self.cancellable)
    }
}

// MARK: - 탭 제스처 관련
extension OriginalViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: mainPDFView)
        
        // 버튼 annotation이 있는 위치인지 확인
        if let page = mainPDFView.page(for: location, nearest: true),
           let annotation = page.annotation(at: mainPDFView.convert(location, to: page)),
           annotation.widgetFieldType == .button {
            return true
        }
        return false
    }
}

//#Preview {
//    OriginalViewController(viewModel: .init(), commentViewModel: .init(mainPDFViewModel: .init()))
//}
