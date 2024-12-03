//
//  EditFigNameView.swift
//  Reazy
//
//  Created by  Lucid on 11/25/24.
//

import SwiftUI

struct EditFigNameView: View {
    
    @EnvironmentObject var floatingViewModel: FloatingViewModel
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
                        if focusFigureViewModel.isFigure {
                            focusFigureViewModel.editFigTitle(at: id, head: newFigName)
                        } else {
                            focusFigureViewModel.editColletionTitle(at: id, head: newFigName)
                        }
                        self.floatingViewModel.updateFloatingTitle(at: id, head: newFigName)
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
            if focusFigureViewModel.isFigure {
                newFigName = focusFigureViewModel.figures.first(where: { $0.uuid == id })?.head ?? ""
            } else {
                newFigName = focusFigureViewModel.collections.first(where: { $0.uuid == id })?.head ?? ""
            }
        }
    }
}
