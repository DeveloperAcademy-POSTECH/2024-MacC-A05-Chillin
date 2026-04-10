//
//  DrawingView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct DrawingView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    
    @State private var isHorizontal = false
    
    var body: some View {
        Group {
            if isHorizontal {
                HStack(spacing: 10) {
                    DrawingToolBar()
                }
                .padding(.horizontal, 6)
            } else {
                VStack(spacing: 10) {
                    DrawingToolBar()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 1.0), value: isHorizontal)
    }
    
    
    @ViewBuilder
    private func DrawingToolBar() -> some View {
        Button(action: {
            mainPDFViewModel.highlightButtonTapped()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(mainPDFViewModel.statusStack.isHighlightSelected ? .primary3 : .clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(.highlight)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 18)
                        .foregroundStyle(.gray800)
                )
        }
        
        ForEach(HighlightColors.allCases, id: \.self) { color in
            HighlightColorButton(button: $mainPDFViewModel.selectedHighlightColor, selectedButton: color) {
                mainPDFViewModel.highlightColorButtonTapped(color)
            }
        }
        
        divider()
        
        if UIDevice.current.userInterfaceIdiom == .pad &&
            !ProcessInfo.processInfo.isMacCatalystApp {
            
            Button(action: {
                mainPDFViewModel.pencilButtonTapped()
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(mainPDFViewModel.statusStack.isPencilSelected ? .primary3 : .clear)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(.pencil)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 18)
                            .foregroundStyle(.gray800)
                    )
            }
            
            ForEach(PenColors.allCases, id: \.self) { color in
                PenColorButton(
                    button: $mainPDFViewModel.selectedPenColor,
                    selectedButton: color
                ) {
                    mainPDFViewModel.pencilColorButtonTapped(color)
                }
            }
            
            divider()
        }
        
        Button(action: {
            mainPDFViewModel.eraserButtonTapped()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(mainPDFViewModel.statusStack.isEraserSelected ? .primary3 : .clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "eraser")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray800)
                )
        }
        
        divider()
        
        Button(action: {
            mainPDFViewModel.pdfDrawer.undo()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(.clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray800)
                )
        }
        .disabled(!mainPDFViewModel.canUndo) // 비활성화
        .opacity(mainPDFViewModel.canUndo ? 1.0 : 0.5)
        
        Button(action: {
            mainPDFViewModel.pdfDrawer.redo()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(.clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16))
                        .foregroundStyle(.gray800)
                )
        }
        .disabled(!mainPDFViewModel.canRedo) // 비활성화
        .opacity(mainPDFViewModel.canRedo ? 1.0 : 0.5)
        
        divider()
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isHorizontal.toggle()
            }
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(.clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: isHorizontal ? "arrow.up.and.down" : "arrow.left.and.right")
                        .font(.system(size: 15))
                        .foregroundStyle(.gray700)
                )
        }
        Button(action: {
            mainPDFViewModel.statusStack.centerMenuOff()
        }) {
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(.clear)
                .frame(width: 26, height: 26)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 15))
                        .foregroundStyle(.gray700)
                )
        }
        
    }
    
    @ViewBuilder
    private func divider() -> some View {
        if isHorizontal {
            // 가로 툴바
            Rectangle()
                .frame(width: 1, height: 32)
                .foregroundStyle(.primary3)
                .padding(.horizontal, 6)
        } else {
            // 세로 툴바
            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundStyle(.primary3)
                .padding(.vertical, 6)
        }
        
    }
}

