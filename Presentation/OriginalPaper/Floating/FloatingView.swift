//
//  FloatingView.swift
//  Reazy
//
//  Created by 유지수 on 10/20/24.
//

import SwiftUI
import PDFKit

struct FloatingView: View {
    
    let documentID: String
    let document: PDFDocument
    let head: String
    
    @Binding var isSelected: Bool
    @Binding var viewOffset: CGSize
    @Binding var viewWidth: CGFloat
    
    @State private var aspectRatio: CGFloat = 1.0
    @State private var isSaveImgAlert = false
    
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack(spacing: 0) {
                    Button(action: {
                        floatingViewModel.setSplitDocument(documentID: documentID)
                    }, label: {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray600)
                    })
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
//                            saveFigImage()
                            saveFigAlert()
                            
                            print("Download Image")
                            
                        }, label: {
                            Text("사진 앱에 저장")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                                .frame(width: 148)
                        })
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.gray600)
                    }
                    .padding(.trailing, 20)
                    
                    Button(action: {
                        floatingViewModel.deselect(documentID: documentID)
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray600)
                    })
                }
                
                Text(head)
                    .reazyFont(.body3)
                    .foregroundStyle(.gray800)
            }
            .padding(.bottom, 11)
            .padding(.horizontal, 16)
            .frame(height: 40)
            
            Divider()
            
            ZStack {
                PDFKitView(document: document, isScrollEnabled: true)
                    .frame(width: viewWidth - 36, height: (viewWidth - 36) / aspectRatio)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                
                if isSaveImgAlert {
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
                    .padding(.bottom, 48)
                }
            }
        }
        .frame(width: viewWidth)
        .padding(.vertical, 11)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            Image(systemName: "righttriangle.fill")
                .frame(width: 80, height: 80)
                .offset(x: 20, y: 20)
                .foregroundStyle(.gray600)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 최대 크기 제한 850 + 최소 크기 제한 300
                            let newWidth = max(min(viewWidth + value.translation.width, 850), 300)
                            self.viewWidth = newWidth
                        }
                )
                .padding(.leading, 100)
                .padding(.top, 100),
            alignment: .bottomTrailing
        )
        .offset(viewOffset)
        .onAppear {
            // PDF의 첫 번째 페이지 크기를 기준으로 비율 결정
            if let page = document.page(at: 0) {
                let pageRect = page.bounds(for: .mediaBox)
                self.aspectRatio = pageRect.width / pageRect.height
                self.viewWidth = pageRect.width
            }
        }
    }
    
    // Fig 이미지 저장 Alert 함수
    private func saveFigAlert() {
        withAnimation {
            isSaveImgAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isSaveImgAlert = false
            }
        }
    }
}
