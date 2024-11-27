//
//  FloatingViewsContainer.swift
//  Reazy
//
//  Created by 유지수 on 10/29/24.
//

import SwiftUI

struct FloatingViewsContainer: View {
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    let geometry: GeometryProxy
    
    var body: some View {
        ForEach(floatingViewModel.droppedFigures, id: \.id) { droppedFigure in
            if droppedFigure.isSelected && !droppedFigure.isInSplitMode {
                FloatingView(
                    isFigure: droppedFigure.isFigure,
                    documentID: droppedFigure.documentID,
                    document: droppedFigure.document,
                    head: droppedFigure.head,
                    isSelected: Binding(
                        get: { droppedFigure.isSelected },
                        set: { newValue in
                            if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                                floatingViewModel.droppedFigures[index].isSelected = newValue
                                if newValue {
                                    floatingViewModel.topmostIndex = index
                                }
                            }
                        }
                    ),
                    viewOffset: Binding(
                        get: { droppedFigure.viewOffset },
                        set: { newValue in
                            if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                                floatingViewModel.droppedFigures[index].viewOffset = newValue
                            }
                        }
                    ),
                    viewWidth: Binding(
                        get: { droppedFigure.viewWidth },
                        set: { newValue in
                            if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                                floatingViewModel.droppedFigures[index].viewWidth = max(newValue, 200)
                            }
                        }
                    )
                )
                .environmentObject(floatingViewModel)
                .aspectRatio(contentMode: .fit)
                .shadow(
                    color: Color(hex: "4D4A97").opacity(0.20),
                    radius: 12,
                    x: 0,
                    y: 2)
                .padding(4.5)
                .zIndex(floatingViewModel.topmostIndex == floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) ? 1 : 0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                                let newOffset = CGSize(
                                    width: floatingViewModel.droppedFigures[index].lastOffset.width + value.translation.width,
                                    height: floatingViewModel.droppedFigures[index].lastOffset.height + value.translation.height
                                )
                                
                                
                                let maxX = geometry.size.width / 2 - floatingViewModel.droppedFigures[index].viewWidth / 2 + 200
                                let minX = -(geometry.size.width / 2 - floatingViewModel.droppedFigures[index].viewWidth / 2) - 200
                                let maxY = geometry.size.height / 2 - 150 + 200
                                let minY = -(geometry.size.height / 2 - 150) - 200
                                
                                floatingViewModel.droppedFigures[index].viewOffset = CGSize(
                                    width: min(max(newOffset.width, minX), maxX),
                                    height: min(max(newOffset.height, minY), maxY)
                                )
                            }
                        }
                        .onEnded { _ in
                            if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                                floatingViewModel.droppedFigures[index].lastOffset = floatingViewModel.droppedFigures[index].viewOffset
                            }
                        }
                )
                .onTapGesture {
                    if let index = floatingViewModel.droppedFigures.firstIndex(where: { $0.id == droppedFigure.id }) {
                        floatingViewModel.topmostIndex = index
                    }
                }
            }
        }
    }
}
