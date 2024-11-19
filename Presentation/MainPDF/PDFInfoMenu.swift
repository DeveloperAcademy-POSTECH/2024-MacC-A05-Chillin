//
//  PDFInfoMenu.swift
//  Reazy
//
//  Created by 김예림 on 11/18/24.
//

import SwiftUI
import PDFKit
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    let excludedTypes: Array<UIActivity.ActivityType> = [
        .markupAsPDF
        ]

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}

struct PDFInfoMenu: View {
    private let pdfSharedData: PDFSharedData = .shared
    @State private var isActivityViewPresented = false
      
    var body: some View {
        VStack(spacing: 12) {
            
            Button(action: {
                isActivityViewPresented = true
            }, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(pdfSharedData.paperInfo!.title)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 5)
                            .lineLimit(2)
                            .reazyFont(.h3)
                            .foregroundStyle(.gray900)
                        
                        Text("마지막 수정 : \(timeAgoString(from: pdfSharedData.paperInfo!.lastModifiedDate))")
                            .reazyFont(.text2)
                            .foregroundStyle(.gray600)
                    }
                    .padding(.trailing, 10)
                    
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .padding(6)
                        .foregroundStyle(.gray800)
                        .background(
                            Circle()
                                .foregroundStyle(.gray300)
                        )
                        .padding(6)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(.gray100)
                )
            })
            .popover(isPresented: $isActivityViewPresented, content: {
                if let url = pdfSharedData.document?.documentURL {
                    ActivityViewController(activityItems: [url])
                }
            })
            
            VStack(spacing: 10) {
                Button(action: {
                    // TODO : 제목 수정 action
                    
                }, label: {
                    HStack{
                        Text("제목 수정")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "pencil")
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                .padding(.top, 12)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    // TODO : 논문에 메모 action
                    
                }, label: {
                    HStack{
                        Text("논문에 메모")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "square.and.pencil")
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    // TODO : 즐겨찾기 action
                    
                }, label: {
                    HStack{
                        Text("즐겨찾기")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "star")
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    // TODO : 이동 action
                    
                }, label: {
                    HStack{
                        Text("이동")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "ipad.and.arrow.forward")
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    // TODO : 삭제 action
                    
                }, label: {
                    HStack{
                        Text("삭제")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(systemName: "trash")
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.pen1)
                .padding(.bottom, 12)
            }
            .background(.gray100)
            .cornerRadius(12)
        }
        .frame(width: 288)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
                .shadow(
                    color: Color(hex: "3C3D4B").opacity(0.08),
                    radius: 16,
                    x: 0,
                    y: 0)
        )
    }
}

extension PDFInfoMenu {
    // TODO : - 브리 ViewModel 만들때 통합하기
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "오늘 HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "어제 HH:mm"
            return dateFormatter.string(from: date)
        } else {
            // 이틀 전 이상의 날짜 포맷으로 반환
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy. MM. dd. a h:mm"
            dateFormatter.amSymbol = "오전"
            dateFormatter.pmSymbol = "오후"
            return dateFormatter.string(from: date)
        }
    }
    
    private func getThumbnail() -> UIImage? {
        var image: UIImage?
        if let document = pdfSharedData.document {
            if let page = document.page(at: 0) {
                let pageSize = page.bounds(for: .mediaBox).size
                image = page.thumbnail(of: pageSize, for: .mediaBox)
            }
        }
        return image
    }
}


#Preview {
    PDFInfoMenu()
}
