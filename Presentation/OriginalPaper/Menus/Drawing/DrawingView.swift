//
//  DrawingView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct DrawingView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State private var selectedHighlightColor: HighlightColors?
    @State private var selectedPenColor: PenColors?

    @State var isHighlight: Bool = false
    @State var isPencil: Bool = false
    @State var isEraser: Bool = false
    @Binding var selectedButton: Buttons? 

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                isHighlight.toggle()
                mainPDFViewModel.drawingToolMode = .highlight
                if selectedHighlightColor == nil {
                    selectedHighlightColor = .yellow
                } else {
                    selectedHighlightColor = nil
                }

                isPencil = false
                selectedPenColor = nil
                isEraser = false
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(isHighlight ? .primary3 : .clear)
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
            .padding(.bottom, 10)

            ForEach(HighlightColors.allCases, id: \.self) { color in
                HighlightColorButton(button: $selectedHighlightColor, selectedButton: color) {
                    isHighlight = true
                    selectedHighlightColor = color
                    mainPDFViewModel.drawingToolMode = .highlight
                    mainPDFViewModel.selectedHighlightColor = color

                    isPencil = false
                    selectedPenColor = nil
                    isEraser = false
                }
                .padding(.bottom, color == .blue ? 16 : 10)
            }

            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundStyle(.primary3)
                .padding(.bottom, 12)

            Button(action: {
                isPencil.toggle()
                mainPDFViewModel.drawingToolMode = .pencil
                mainPDFViewModel.updateDrawingTool()
                if selectedPenColor == nil {
                    selectedPenColor = .black
                } else {
                    selectedPenColor = nil
                }

                isHighlight = false
                selectedHighlightColor = nil
                isEraser = false
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(isPencil ? .primary3 : .clear)
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
            .padding(.bottom, 10)

            ForEach(PenColors.allCases, id: \.self) { color in
                PenColorButton(button: $selectedPenColor, selectedButton: color) {
                    isPencil = true
                    selectedPenColor = color
                    mainPDFViewModel.drawingToolMode = .pencil
                    mainPDFViewModel.pdfDrawer.penColor = selectedPenColor!

                    isHighlight = false
                    selectedHighlightColor = nil
                    isEraser = false
                }
                .padding(.bottom, color == .green ? 16 : 10)
            }

            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundStyle(.primary3)
                .padding(.bottom, 12)

            Button(action: {
                isEraser.toggle()
                mainPDFViewModel.drawingToolMode = .eraser

                isPencil = false
                selectedPenColor = nil

                isHighlight = false
                selectedHighlightColor = nil
            }) {
                RoundedRectangle(cornerRadius: 6)
                    .foregroundStyle(isEraser ? .primary3 : .clear)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: "eraser")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray800)
                    )
            }
            .padding(.bottom, 12)

            Rectangle()
                .frame(width: 32, height: 1)
                .foregroundStyle(.primary3)
                .padding(.bottom, 12)

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
            .padding(.bottom, 9)
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
            
            Button(action: {
                selectedButton = nil
                mainPDFViewModel.toolMode = .none
                mainPDFViewModel.drawingToolMode = .none
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
            .padding(.top, 18)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 10)
    }
}
