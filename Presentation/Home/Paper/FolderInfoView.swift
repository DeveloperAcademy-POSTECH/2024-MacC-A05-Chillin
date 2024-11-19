//
//  FolderInfoView.swift
//  Reazy
//
//  Created by 유지수 on 11/19/24.
//

import SwiftUI

struct FolderInfoView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    let id: UUID
    let title: String
    let color: Color
    @State var memo: String?
    var isFavorite: Bool
    
    @State var isStarSelected: Bool
    
    @State private var isDeleteConfirm: Bool = false
    
    @Binding var isEditingTitle: Bool
    @Binding var isEditingMemo: Bool
    
    let onNavigate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // TODO: - [브리] 이미지 수정 필요
            RoundedRectangle(cornerRadius: 12)
                .frame(width: 295, height: 378)
                .foregroundStyle(.primary2)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .frame(width: 135, height: 135)
                        .foregroundStyle(color)
                        .overlay(
                            Image("folder")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 69)
                        )
                )
            
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
                    self.isDeleteConfirm.toggle()
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
                    
                    if !(self.memo == nil) {
                        Menu {
                            Button("수정", systemImage: "pencil") {
                                self.isEditingMemo = true
                            }
                            
                            Button("삭제", systemImage: "trash", role: .destructive) {
                                self.memo = nil
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
                            self.memo = ""
                            self.isEditingMemo = true
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
    FolderInfoView(
        id: .init(),
        title: "테스트",
        color: .primary1,
        memo: "",
        isFavorite: false,
        isStarSelected: false,
        isEditingTitle: .constant(false),
        isEditingMemo: .constant(false),
        onNavigate: {},
        onDelete: {}
    )
}
