//
//  SettingView.swift
//  Reazy
//
//  Created by 김예림 on 11/24/24.
//

import SwiftUI
import StoreKit

struct SupportEmailModel {
    let toAddress: String = "fromchillin@gmail.com"
    let subject: String = "[Reazy] 관련 문의"
    var body: String {"""
        안녕하세요! 
        \nReazy을 사용해 주셔서 정말 감사합니다. 
        \n앱을 사용하시면서 궁금한 점이나 불편한 점이 있으셨다면 언제든지 알려주세요🙌

        \n문의 내용을 작성하시기 전에 아래 정보를 알려주시면 더욱 빠르게 해결해 드릴 수 있어요.

        \n문의 종류: (ex. 오류 신고, 기능 요청, 기타)
        \n사용 중인 기기: (ex. iPad Pro 11, iPad Air 4세대)
        \niOS 버전: (ex. iOS 17.0.3)

        \n문의 내용: [여기에 문의 내용을 적어주세요!]

        \n저희 팀에서 확인 후 빠른 시일 내에 답변 드리겠습니다.  오늘도 좋은 하루 보내세요! 감사합니다😊
    """
    }
    
    // openURL
    func send(openURL: OpenURLAction) {
        let urlString = "mailto:\(toAddress)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")"
        guard let url = URL(string: urlString) else { return }
        openURL(url) { accepted in
            if !accepted {
                print("ERROR: 현재 기기는 이메일을 지원하지 않습니다.")
            }
        }
    }
}

struct SettingView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL
    private var email = SupportEmailModel()
    @State var isDismiss: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
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
                    
                    Link(destination: URL(string: "https://linktr.ee/Reazy.official")!, label: {
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
                        email.send(openURL: openURL)
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
