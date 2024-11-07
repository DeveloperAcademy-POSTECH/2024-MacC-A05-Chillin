//
//  PaperInfoView.swift
//  Reazy
//
//  Created by 유지수 on 10/18/24.
//

import SwiftUI

struct PaperInfoView: View {
    @EnvironmentObject var pdfFileManager: PDFFileManager
    
    let id: UUID
    let image: Data
    let title: String
    let author: String
    let pages: Int
    let publisher: String
    let dateTime: String
    var isFavorite: Bool
    
    @State var isStarSelected: Bool
    @State private var text: String = ""
    
    @Binding var isEditingTitle: Bool
    
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
                Button(action: {
                    isStarSelected.toggle()
                    pdfFileManager.updateFavorite(at: id, isFavorite: isStarSelected)
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 17)
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
                                .resizable()
                                .scaledToFit()
                                .frame(height: 17)
                                .foregroundStyle(.gray600)
                        )
                }
                .padding(.trailing, 6)
                
                Button(action: {
                    isEditingTitle.toggle()
                }) {
                    RoundedRectangle(cornerRadius: 14)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(.gray400)
                        .overlay(
                            Image(systemName: "ellipsis.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 17)
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
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                .padding(.bottom, 13)
                
                
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundStyle(.gray200)
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1)
                        .foregroundStyle(.gray550)
                    
                    VStack {
                        TextField("메모를 입력해주세요.", text: $text, axis: .vertical)
                            .lineLimit(5)
                            .reazyFont(.body2)
                            .foregroundStyle(.gray700)
                            
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                        
                }
                .frame(maxHeight: 120)
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
        onNavigate: {},
        onDelete: {}
    )
}
