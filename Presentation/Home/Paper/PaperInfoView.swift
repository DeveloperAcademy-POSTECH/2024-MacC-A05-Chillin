//
//  PaperInfoView.swift
//  Reazy
//
//  Created by 유지수 on 10/18/24.
//

import SwiftUI
import PDFKit

struct PaperInfoView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    let id: UUID
    let image: Data
    let title: String
    @State var memo: String?
    var isFavorite: Bool
    
    @State var isStarSelected: Bool
    
    @State private var isDeleteConfirm: Bool = false
    
    @Binding var isEditingTitle: Bool
    @Binding var isEditingMemo: Bool
    @Binding var isMovingFolder: Bool
    
    let onNavigate: () -> Void
    let onDelete: () -> Void
    
    @State private var isActivityViewPresented = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .init(data: image) ?? .init(resource: .testThumbnail))
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 30)
            
            HStack(spacing: 0) {
                Text(title)
                    .reazyFont(.text1)
                    .foregroundStyle(.gray900)
                    .padding(.horizontal, 30)
                    .padding(.top, 14)
                    .lineLimit(2)
                Spacer()
            }
            
            HStack(spacing: 0) {
                Menu {
                    Button {
                        self.isEditingTitle = true
                    } label: {
                        HStack(spacing: 0) {
                            Text("제목 수정")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(.editpencil)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                                .foregroundStyle(.gray800)
                        }
                    }
                    
                    Button {
                        // TODO: - 문서 복제 구현
                    } label: {
                        HStack(spacing: 0) {
                            Text("복제")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(.copy)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                                .foregroundStyle(.gray800)
                        }
                    }
                    
                    Button {
                        self.isMovingFolder.toggle()
                    } label: {
                        HStack(spacing: 0) {
                            Text("이동")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(.move)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                                .foregroundStyle(.gray800)
                        }
                    }
                    
                    Button(role: .destructive) {
                        // TODO: - Alert 오류 추후 수정 필요
//                        self.isDeleteConfirm.toggle()
                        self.homeViewModel.deletePDF(at: id)
                        onDelete()
                    } label: {
                        HStack(spacing: 0) {
                            Text("삭제")
                                .reazyFont(.body1)
                            Spacer()
                            Image(.trash)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17, height: 17)
                        }
                    }
                    
                } label: {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(.morehorizontal)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray600)
                        )
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    isStarSelected.toggle()
                    homeViewModel.updatePaperFavorite(at: id, isFavorite: isStarSelected)
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(isFavorite ? .starfill : .star)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(isFavorite ? .primary1 : .gray600)
                        )
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    isActivityViewPresented = true
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(.share)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray600)
                        )
                }
                .popover(isPresented: $isActivityViewPresented,
                         attachmentAnchor: .point(.leading),
                         arrowEdge: .trailing,
                         content: {
                    if let url = homeViewModel.getPapaerURL(at: id) {
                        ActivityViewController(activityItems: [url])
                    }
                })
                
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
                    
                    if !(self.memo == nil) {
                        Menu {
                            Button {
                                self.isEditingMemo = true
                            } label: {
                                HStack(spacing: 0) {
                                    Text("메모 수정")
                                        .reazyFont(.body1)
                                        .foregroundStyle(.gray800)
                                    Spacer()
                                    Image(.editpencil)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 17, height: 17)
                                        .foregroundStyle(.gray800)
                                }
                            }
                            
                            Button(role: .destructive) {
                                self.homeViewModel.deleteMemo(at: id)
                                self.memo = nil
                            } label: {
                                HStack(spacing: 0) {
                                    Text("삭제")
                                        .reazyFont(.body1)
                                    Spacer()
                                    Image(.trash)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 17, height: 17)
                                }
                            }
                            
                        } label: {
                            Image(.morecircle)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray600)
                        }
                    } else {
                        Button {
                            self.memo = ""
                            self.isEditingMemo = true
                        } label: {
                            Image(.memo)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray600)
                        }
                    }
                    
                }
                .padding(.bottom, 13)
                
                if self.memo != nil {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundStyle(.gray200)
                        
                        
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray550)
                        
                        VStack {
                            Text(self.memo!)
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
        .onChange(of: self.id) {
            let paperInfo = homeViewModel.paperInfos.first { $0.id == self.id }!
            self.memo = paperInfo.memo
        }
        .onChange(of: self.homeViewModel.memoText) {
            self.memo = self.homeViewModel.memoText
        }
        .onChange(of: self.isEditingMemo) {
            self.homeViewModel.memoText = memo!
        }
        // TODO: - Alert 수정 필요
//        .alert(isPresented: $isDeleteConfirm) {
//            Alert(
//                title: Text("정말 삭제하시겠습니까?"),
//                message: Text("삭제된 파일은 복구할 수 없습니다."),
//                primaryButton: .default(Text("취소")),
//                secondaryButton: .destructive(Text("삭제")) {
//                    let ids = [id]
//                    self.homeViewModel.deletePDF(ids: ids)
//                    onDelete()
//                }
//            )
//        }
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
            homeViewModel.updateLastModifiedDate(at: id, lastModifiedDate: .init())
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
        memo: "",
        isFavorite: false,
        isStarSelected: false,
        isEditingTitle: .constant(false),
        isEditingMemo: .constant(false),
        isMovingFolder: .constant(false),
        onNavigate: {},
        onDelete: {}
    )
}
