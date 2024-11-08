//
//  PaperInfoView.swift
//  Reazy
//
//  Created by 유지수 on 10/18/24.
//

import SwiftUI

struct PaperInfoView: View {
    @EnvironmentObject var pdfFileManager: PDFFileManager
    
    // TODO: memo 추가 필요
    let id: UUID
    let image: Data
    let title: String
    let author: String
    let pages: Int
    let publisher: String
    let dateTime: String
    var isFavorite: Bool
    
    @State var isStarSelected: Bool
    
    // TODO: 임시 메모 텍스트, 및 있는지 모델 반영 필요
    @State private var memoText: String = ""
    @State var isMemo: Bool = false
    
    @State private var timer: Timer?
    
    @Binding var isEditingTitle: Bool
    @Binding var isEditingMemo: Bool
    
    let onNavigate: () -> Void
    let onDelete: () -> Void
    
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .init(data: image) ?? .init(resource: .testThumbnail))
                .resizable()
                .scaledToFit()
                .frame(height: 370)
                .padding(.horizontal, 30)
            
            Text(title)
                .reazyFont(.text1)
                .foregroundStyle(.gray900)
                .padding(.horizontal, 30)
                .padding(.top, 14)
                .lineLimit(2)
            
            HStack(spacing: 0) {
                Menu {
                    Button("제목 수정", systemImage: "pencil") {
                        self.isEditingTitle = true
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray600)
                        )
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    isStarSelected.toggle()
                    pdfFileManager.updateFavorite(at: id, isFavorite: isStarSelected)
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .font(.system(size: 14))
                                .foregroundStyle(isFavorite ? .primary1 : .gray600)
                        )
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    pdfFileManager.deletePDFFile(at: id)
                    onDelete()
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(systemName: "trash")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray600)
                        )
                }
                
                Spacer()
                
                actionButton()
            }
            .padding(.horizontal, 30)
            .padding(.top, 16)
            
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .padding(.bottom, 10)
                    .foregroundStyle(.primary3)
                
                HStack(spacing: 0) {
                    Text("메모")
                        .reazyFont(.button1)
                        .foregroundStyle(.black)
                    
                    Spacer()
                    
                    if isMemo {
                        Menu {
                            Button("수정", systemImage: "pencil") {
                                self.isEditingMemo = true
                            }
                            
                            Button("삭제", systemImage: "trash") {
                                // TODO: 메모 삭제 기능 구현
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                                .foregroundStyle(.gray600)
                        }
                    } else {
                        Button {
                            isMemo.toggle()
                        } label: {
                            Image(systemName: "plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                                .foregroundStyle(.gray600)
                        }
                    }
                    
                }
                .padding(.bottom, 13)
                
                if isMemo {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.gray200)
                        
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray550)
                        
                        VStack {
                            // TODO: 메모 데이터 연결 필요
                            Text("이 편지는 영국에서 시작되어....")
                                .lineLimit(4)
                                .reazyFont(.body2)
                                .foregroundStyle(.gray700)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        
                    }
                    .frame(maxHeight: 120)
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .padding(.top, 36)
        .background(alignment: .bottom) {
            LinearGradient(colors: [.init(hex: "DADBEA"), .clear], startPoint: .bottom, endPoint: .top)
                .frame(height: 185)
        }
        .onChange(of: memoText) { _, newValue in
            if let timer = self.timer {
                timer.invalidate()
            }
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                // TODO: PDF 메모 업데이트 메소드 구현
                self.pdfFileManager.updateMemo()
            }
        }
        .onAppear {
            // TODO: 메모 있을 시 연동
//            self.memoText = self.paperInfo.memo
        }
    }
    
    @ViewBuilder
    private func divider() -> some View {
        Rectangle()
            .frame(height: 1)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .foregroundStyle(.primary3)
    }
    
    @ViewBuilder
    private func actionButton() -> some View {
        Button(action: {
            onNavigate()
            pdfFileManager.updateLastModifiedDate(at: id, lastModifiedDate: Date())
        }) {
            HStack(spacing: 0) {
                Text("읽기 ")
                Image(systemName: "arrow.up.right")
            }
            .foregroundStyle(.gray100)
            .reazyFont(.button2)
            .padding(.horizontal, 21)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color(hex:"3F3E7E"), location: 0),
                                .init(color: Color(hex: "313070"), location: 1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "383582").opacity(0.2), radius: 30, x: 0, y: 6)
            )
        }
        .frame(height: 40)
    }
}


#Preview {
    PaperInfoView(
        id: .init(),
        image: .init(),
        title: "A review of the global climate change impacts, adaptation, and sustainable mitigation measures",
        author: "Smith, John",
        pages: 43,
        publisher: "NATURE",
        dateTime: "1999-06-23",
        isFavorite: false,
        isStarSelected: false,
        isEditingTitle: .constant(false),
        isEditingMemo: .constant(false),
        onNavigate: {},
        onDelete: {}
    )
}
