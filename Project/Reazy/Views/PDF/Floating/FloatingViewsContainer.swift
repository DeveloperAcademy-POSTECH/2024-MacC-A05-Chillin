//
//  FloatingViewsContainer.swift
//  Reazy
//
//  Created by 유지수 on 10/29/24.
//

import SwiftUI

struct FloatingViewsContainer: View {
  @EnvironmentObject var floatingViewModel: FloatingViewModel
  let geometry: GeometryProxy
  
  var body: some View {
    ForEach(floatingViewModel.droppedFigures.indices, id: \.self) { index in
      let droppedFigure = floatingViewModel.droppedFigures[index]
      let isTopmost = (floatingViewModel.topmostIndex == index)
      
      if droppedFigure.isSelected {
        FloatingView(
          documentID: droppedFigure.documentID,
          document: droppedFigure.document,
          head: droppedFigure.head,
          isSelected: Binding(
            get: { droppedFigure.isSelected },
            set: { newValue in
              floatingViewModel.droppedFigures[index].isSelected = newValue
              if newValue {
                floatingViewModel.topmostIndex = index
              }
            }
          ),
          viewOffset: Binding(
            get: { floatingViewModel.droppedFigures[index].viewOffset },
            set: { floatingViewModel.droppedFigures[index].viewOffset = $0 }
          ),
          viewWidth: Binding(
            get: { floatingViewModel.droppedFigures[index].viewWidth },
            set: { floatingViewModel.droppedFigures[index].viewWidth = $0 }
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
        .zIndex(isTopmost ? 1 : 0)
        .gesture(
          DragGesture()
            .onChanged { value in
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
            .onEnded { _ in
              floatingViewModel.droppedFigures[index].lastOffset = floatingViewModel.droppedFigures[index].viewOffset
            }
        )
        .onTapGesture {
          floatingViewModel.topmostIndex = index
        }
      }
    }
  }
}
