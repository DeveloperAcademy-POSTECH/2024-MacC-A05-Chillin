//
//  CollectionMenu.swift
//  Reazy
//
//  Created by 유지수 on 11/27/24.
//

import SwiftUI

struct CollectionMenu: View {
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    @ObservedObject var observableDocument: ObservableDocument
    
    @Binding var newFigName: String
    @Binding var isDeleteFigAlert: Bool
    @Binding var isSavedLocation: Bool
    
    let id: UUID
    
    @State private var head: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Menu {
                    // Fig 이름 수정
                    Button(action: {
                        focusFigureViewModel.isEditFigName = true
                        self.focusFigureViewModel.selectedID = id
                        self.focusFigureViewModel.isFigure = false
                        
                        print("Edit FigName")
                        
                    }, label: {
                        HStack {
                            Text("이름 수정")
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
                    })
                    
                    // Fig 사진 앱에 저장
                    Button(action: {
                        floatingViewModel.saveFigImage(document: observableDocument)
                        floatingViewModel.saveFigAlert()
                        self.focusFigureViewModel.selectedID = id
                        self.isSavedLocation = true
                        
                        print("Save Fig")
                        
                    }, label: {
                        HStack {
                            Text("사진 앱에 저장")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                            
                            Spacer()
                            
                            Image(.share)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.gray800)
                        }
                    })
                    
                    // Fig 삭제
                    Button(role: .destructive, action: {
                        isDeleteFigAlert = true
                    }, label: {
                        HStack {
                            Text("삭제")
                                .reazyFont(.body1)
                            
                            Spacer()
                            
                            Image(.trash)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 17)
                                .foregroundStyle(.pen1)
                        }
                    })
                    
                } label: {
                    Image(.editfigure)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundStyle(.gray600)
                }
                .foregroundStyle(.primary2)
                .padding(.leading, 10)
                .padding(.bottom, 10)
                
                Spacer()
            }
        }
        .onAppear {
            if let collection = focusFigureViewModel.collections.first(where: { $0.uuid == id }) {
                self.head = collection.head
            }
        }
        .alert(
            "\(head)을 삭제하시겠습니까?",
            isPresented: $isDeleteFigAlert,
            presenting: id
        ) { id in
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                self.focusFigureViewModel.deleteCollection(at: id)
                self.floatingViewModel.deselect(uuid: id)
            }
        } message: { id in
            Text("삭제된 항목은 복구할 수 없습니다.")
        }
    }
}
