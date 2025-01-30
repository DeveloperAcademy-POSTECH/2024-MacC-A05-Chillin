//
//  DrawingView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct DrawingView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State var selectedHighlightColor: HighlightColors?
    @State var selectedPenColor: PenColors?
    @Binding var selectedButton: Buttons?
    
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
        .onAppear {
            selectedPenColor = mainPDFViewModel.selectedPenColor
            selectedHighlightColor = mainPDFViewModel.selectedHighlightColor
        }
        .onChange(of: mainPDFViewModel.selectedPenColor){
            selectedPenColor = mainPDFViewModel.selectedPenColor
        }
        .onChange(of: mainPDFViewModel.selectedHighlightColor){
            selectedHighlightColor = mainPDFViewModel.selectedHighlightColor
        }
        .animation(.easeInOut(duration: 1.0), value: isHorizontal)
    }
    
    
    @ViewBuilder
    private func DrawingToolBar() -> some View {
            Button(action: {
                mainPDFViewModel.toggleHighlight()
                
                if mainPDFViewModel.isHighlight {
                    mainPDFViewModel.pdfDrawer.drawingTool = .highlights
                    mainPDFViewModel.toolMode = .drawing
                } else {
                    mainPDFViewModel.pdfDrawer.drawingTool = .none
                }
                
                if selectedHighlightColor == nil {
                    selectedHighlightColor = .yellow
                } else {
                    selectedHighlightColor = nil
                }

                mainPDFViewModel.isPencil = false
                mainPDFViewModel.selectedPenColor = nil
                mainPDFViewModel.isEraser = false
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(mainPDFViewModel.isHighlight ? .primary3 : .clear)
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
                HighlightColorButton(button: $selectedHighlightColor, selectedButton: color) {
                    mainPDFViewModel.isHighlight = true
                    mainPDFViewModel.pdfDrawer.drawingTool = .highlights
                    mainPDFViewModel.selectedHighlightColor = color
                    selectedHighlightColor = color

                    mainPDFViewModel.isPencil = false
                    mainPDFViewModel.selectedPenColor = nil
                    mainPDFViewModel.isEraser = false
                }
            }

            divider()

            Button(action: {
                mainPDFViewModel.togglePencil()
                
                if mainPDFViewModel.isPencil {
                    mainPDFViewModel.toolMode = .drawing
                    mainPDFViewModel.pdfDrawer.drawingTool = .pencil
                } else {
                    mainPDFViewModel.pdfDrawer.drawingTool = .none
                    
                }
                
                if selectedPenColor == nil {
                    selectedPenColor = .black
                    mainPDFViewModel.selectedPenColor = .black
                } else {
                    selectedPenColor = nil
                    mainPDFViewModel.selectedPenColor = nil
                }

                mainPDFViewModel.isHighlight = false
                selectedHighlightColor = nil
                mainPDFViewModel.isEraser = false
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(mainPDFViewModel.isPencil ? .primary3 : .clear)
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
                PenColorButton(button: $selectedPenColor, selectedButton: color) {
                    mainPDFViewModel.isPencil = true
                    mainPDFViewModel.selectedPenColor = color
                    mainPDFViewModel.pdfDrawer.drawingTool = .pencil
                    mainPDFViewModel.pdfDrawer.penColor = mainPDFViewModel.selectedPenColor!

                    mainPDFViewModel.isHighlight = false
                    selectedHighlightColor = nil
                    mainPDFViewModel.isEraser = false
                }
            }

            divider()

            Button(action: {
                mainPDFViewModel.toggleEraser()
                
                if mainPDFViewModel.isEraser {
                    mainPDFViewModel.pdfDrawer.drawingTool = .eraser
                } else {
                    mainPDFViewModel.pdfDrawer.drawingTool = .none
                }

                mainPDFViewModel.isPencil = false
                mainPDFViewModel.selectedPenColor = nil

                mainPDFViewModel.isHighlight = false
                selectedHighlightColor = nil
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(mainPDFViewModel.isEraser ? .primary3 : .clear)
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

            // MARK: 툴바 방향 전환
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
                selectedButton = nil
                mainPDFViewModel.toolMode = .none
                mainPDFViewModel.pdfDrawer.drawingTool = .none
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

