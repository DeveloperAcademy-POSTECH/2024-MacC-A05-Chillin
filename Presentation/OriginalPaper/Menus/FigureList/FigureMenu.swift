//
//  FigureMenu.swift
//  Reazy
//
//  Created by  Lucid on 11/22/24.
//

import SwiftUI

struct FigureMenu: View {
    
    @EnvironmentObject var floatingViewModel: FloatingViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Menu {
                    // Fig 이름 수정
                    Button(action: {
                        
                        print("Change FigName")
                        
                    }, label: {
                        HStack {
                            Text("이름 수정")
                                .reazyFont(.body1)
                                .foregroundStyle(.gray800)
                            
                            Spacer()
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
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
                            
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.gray800)
                        }
                    })
                    
                    // Fig 삭제
                    Button(role: .destructive, action: {
                        
                        print("Delete Fig")
                        
                    }, label: {
                        HStack {
                            Text("삭제")
                                .reazyFont(.body1)
                                .foregroundStyle(.pen1)
                            
                            Spacer()
                            
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.pen1)
                        }
                    })
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20, weight: .medium))
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


#Preview {
    FigureMenu()
}
