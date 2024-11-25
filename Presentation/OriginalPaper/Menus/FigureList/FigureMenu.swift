//
//  FigureMenu.swift
//  Reazy
//
//  Created by  Lucid on 11/22/24.
//

import SwiftUI

struct FigureMenu: View {
    
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    
    @ObservedObject var observableDocument: ObservableDocument
    
    @Binding var newFigName: String
    @Binding var isDeleteFigAlert: Bool
    
    let id: UUID
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Menu {
                    // Fig 이름 수정
                    Button(action: {
                        focusFigureViewModel.isEditFigName = true
                        self.focusFigureViewModel.selectedID = id
                        
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
                        focusFigureViewModel.deleteFigure(at: id)
                        
                        print("Delete Fig")
                        
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
    }
}


//#Preview {
//    FigureMenu()
//}
