//
//  FloatingSplitView.swift
//  Reazy
//
//  Created by 유지수 on 10/30/24.
//

import SwiftUI
import PDFKit

struct FloatingSplitView: View {
  
  @EnvironmentObject var mainPDFViewModel: MainPDFViewModel
  @EnvironmentObject var floatingViewModel: FloatingViewModel
  
  let documentID: String
  let document: PDFDocument
  let head: String
  let isFigSelected: Bool
  
  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        ZStack {
          HStack(spacing: 0) {
            Button(action: {
              floatingViewModel.setFloatingDocument(documentID: documentID)
            }, label: {
              Image(systemName: "rectangle")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray600)
            })
            .padding(.horizontal, 20)
            
            Button(action: {
              
            }, label: {
              Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray600)
            })
            
            Spacer()
            
            Button(action: {
              floatingViewModel.deselect(documentID: documentID)
            }, label: {
              Image(systemName: "xmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray600)
            })
            .padding(.trailing, 20)
          }
          
          HStack(spacing: 0) {
            Spacer()
            Button(action: {
              
            }, label: {
              Image(systemName: "chevron.left")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray600)
            })
            Text(head)
              .reazyFont(.h3)
              .foregroundStyle(.gray800)
              .padding(.horizontal, 24)
            Button(action: {
              
            }, label: {
              Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.gray600)
            })
            Spacer()
          }
        }
        .padding(.vertical, 10)
        
        Divider()
          .background(.gray300)
        
        PDFKitView(document: document, isScrollEnabled: true)
          .padding(.horizontal, 30)
          .padding(.vertical, 14)
        
        
        if isFigSelected {
          Divider()
          
          ScrollView(.horizontal) {
            HStack(spacing: 8) {
              ForEach(0..<mainPDFViewModel.figureAnnotations.count, id: \.self) { index in
                FigureCell(index: index, onSelect: { documentID, document, head in
                  floatingViewModel.toggleSelection(for: documentID, document: document, head: head)
                })
                .environmentObject(mainPDFViewModel)
                .environmentObject(floatingViewModel)
                .padding(.trailing, 5)
              }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
          }
          .frame(height: geometry.size.height * 0.2)
        }
      }
    }
  }
}
