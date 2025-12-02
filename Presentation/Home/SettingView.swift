//
//  SettingView.swift
//  Reazy
//
//  Created by 김예림 on 11/24/24.
//

import SwiftUI
import StoreKit
import Translation

struct SettingView: View {
    let url = "https://apps.apple.com/app/id6737178157?action=write-review"
    private var email = SupportEmail()
    private var appVersion: String {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            return "\(version)"
     }
    
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                
                Rectangle()
                    .frame(width: 18, height: 1)
                    .foregroundStyle(.gray200)
                
                Spacer()
                
                Text("설정")
                    .reazyFont(.button1)
                
                Spacer()
                
                Button(action: {
                    homeViewModel.homeViewAction = .none
                }, label: {
                    Text("닫기")
                        .reazyFont(.text1)
                        .foregroundStyle(.primary1)
                })
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            
            Divider()
                .padding(0)
            
            VStack(spacing: 0) {
                
                
                switch Locale.currentLang() {
                case .ko:
                    Image(.settingThumbnailKor)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 480)
                        .padding(.bottom, 30)
                case .en, .etc:
                    Image(.settingThumbnailEng)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 480)
                        .padding(.bottom, 30)
                case .ja:
                    Image(.settingThumbnailJpn)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 480)
                        .padding(.bottom, 30)
                }
                
                List {
                    HStack {
                        Text("버전")
                        Spacer()
                        Text(appVersion)
                    }
                    .foregroundStyle(.gray800)
                    
                    Button(action: {
                        guard let writeReviewURL = URL(string: url) else {
                            fatalError("Expected a valid URL")
                        }
                        openURL(writeReviewURL)
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
                    
                    Link(destination: URL(string: "https://www.instagram.com/reazy.app?igsh=ZXV1bWF1YWV3aHJv")!, label: {
                        HStack {
                            Text("Reazy 인스타그램")
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxHeight: 207)
                .padding(.bottom, 20)
                .scrollDisabled(true)
                
                Text("© 2025 chillin'. All rights reserved.")
                    .reazyFont(.body1)
                    .foregroundStyle(.gray700)
            }
            .padding(20)
        }
        .background(.gray200)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 520, maxHeight: 620)
    }
}

// MARK: - 이메일
private struct SupportEmail {
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
                log("ERROR: 현재 기기는 이메일을 지원하지 않습니다.")
            }
        }
    }
}
