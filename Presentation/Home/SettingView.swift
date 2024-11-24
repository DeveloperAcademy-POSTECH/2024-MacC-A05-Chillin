//
//  SettingView.swift
//  Reazy
//
//  Created by 김예림 on 11/24/24.
//

import SwiftUI
import StoreKit

struct SettingView: View {
    @Environment(\.requestReview) var requestReview
    @State var isDismiss: Bool = false
    
    var body: some View {
        VStack(spacing: 0)
            HStack {
                Spacer()
                
                Text("설정")
                    .reazyFont(.button1)
                
                Spacer()
                
                Button(action: {
                    isDismiss = true
                }, label: {
                    Text("닫기")
                        .reazyFont(.text1)
                        .foregroundStyle(.primary1)
                })
                .padding(.trailing, 20)
            }
            .padding(.vertical, 14)
            
            Divider()
                .padding(0)
            
            VStack {
                
                Image("setting_thumbnail")
                    .resizable()
                    .scaledToFit()
                    .padding(.bottom, 30)
                
                List {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text("1.0.1")
                    }
                    .foregroundStyle(.gray800)
                    
                    Button(action: {
                        requestReview()
                    }, label: {
                        HStack {
                            Text("앱스토어 리뷰 남기기")
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray600)
                        }
                    })
                    
                    Button(action: {
                        
                    }, label: {
                        HStack {
                            Text("더 알아보기")
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray600)
                        }
                    })
                    
                    Button(action: {
                        
                    }, label: {
                        HStack {
                            Text("문의하기")
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray600)
                        }
                    })
                    
                }
                .environment(\.defaultMinListRowHeight, 52)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 208)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 20)
                
                List {
                    Button(action: {
                        
                    }, label: {
                        HStack {
                            Text("언어")
                                .foregroundStyle(.gray800)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray600)
                        }
                    })
                    .listRowSeparator(.hidden)
                }
                .environment(\.defaultMinListRowHeight, 52)
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding(20)
        }
        .background(.gray200)
        .frame(maxWidth: 520, maxHeight: 620)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SettingView()
}
