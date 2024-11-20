//
//  PDFInfoMenu.swift
//  Reazy
//
//  Created by 김예림 on 11/18/24.
//

import SwiftUI
import PDFKit
import UIKit

//MARK: - ActivityView
struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // 제외해야할 activityTypes
        controller.excludedActivityTypes = [.markupAsPDF]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

//MARK: - PDFInfoMenu
struct PDFInfoMenu: View {
    private let pdfSharedData: PDFSharedData = .shared
    @State private var isActivityViewPresented = false
    @EnvironmentObject private var viewModel: PDFInfoMenuViewModel
    
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
                        
                        Text("마지막 수정 : \(viewModel.timeAgoString(from: pdfSharedData.paperInfo!.lastModifiedDate))")
                            .reazyFont(.text2)
                            .foregroundStyle(.gray600)
                    }
                    
                    Spacer()
                    
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
                .frame(maxWidth: 266)
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

#Preview {
    PDFInfoMenu()
}
