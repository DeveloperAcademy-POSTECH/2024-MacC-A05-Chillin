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
    
    @Binding var newFigName: String
    let id: UUID
    
    @Binding var isDeleteFigAlert: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Menu {
                    // Fig 이름 수정
                    Button(action: {
                        focusFigureViewModel.isEditFigName = true
                        self.focusFigureViewModel.selectedID = id
                        print("Change FigName")
                        
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
//                        floatingViewModel.saveFigImage(document: observableDocument)
                        floatingViewModel.saveFigAlert()
                        
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
                        
                        print("isDeleteFigAlert: \(isDeleteFigAlert)")
                        print("Alert Delete Fig")
                        
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


struct EditFigName: View {
    
    @EnvironmentObject var focusFigureViewModel: FocusFigureViewModel
    @State private var newFigName: String = ""
    
    let id: UUID 
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
            
            VStack {
                HStack {
                    Text("이름 수정")
                        .reazyFont(.button1)
                        .foregroundStyle(.primary1)
                        .padding(.leading, 24)
                    
                    Spacer()
                }
                
                ZStack {
                    TextField("피규어 이름을 입력해주세요.", text: $newFigName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundStyle(.gray800)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            newFigName = ""
                        }, label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.gray600)
                        })
                        .padding(.trailing, 12)
                    }
                }
                .frame(width: 400, height: 52)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                HStack {
                    Spacer()

                    Button(action: {
                        focusFigureViewModel.isEditFigName = false
                    }, label: {
                        Text("취소")
                            .foregroundStyle(.primary1)
                    })
                    .padding(.trailing, 16)

                    Button(action: {
                        focusFigureViewModel.editFigTitle(at: id, head: newFigName)
                        focusFigureViewModel.isEditFigName = false
                    }, label: {
                        ZStack {
                            Capsule()
                                .frame(width: 60, height: 32)
                                .foregroundStyle(.point4)

                            Text("저장")
                                .foregroundStyle(.gray200)
                        }
                    })
                    .padding(.trailing, 24)
                }

            }
        }
        .frame(width: 448, height: 200)
        .onAppear {
            newFigName = focusFigureViewModel.figures.first(where: { $0.uuid == id })?.head ?? ""
        }
    }
}


//#Preview {
//    EditFigName()
//}
