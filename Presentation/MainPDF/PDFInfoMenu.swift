//
//  PDFInfoMenu.swift
//  Reazy
//
//  Created by 김예림 on 11/18/24.
//

import SwiftUI
import UIKit

//MARK: - ActivityView
public struct ActivityViewController: UIViewControllerRepresentable {
    
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // 제외해야할 activityTypes
        controller.excludedActivityTypes = [.markupAsPDF]
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

//MARK: - PDFInfoMenu
struct PDFInfoMenu: View {
    private let pdfSharedData: PDFSharedData = .shared
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @EnvironmentObject private var pdfInfoMenuViewModel: PDFInfoMenuViewModel
    @EnvironmentObject private var navigationCoordinator: NavigationCoordinator
    
    @State var title: String?
    @State var isStarSelected: Bool = false
    

    var body: some View {
        VStack(spacing: 12) {
            
            Button(action: {
                pdfInfoMenuViewModel.activityButtonTapped()
            }, label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(title ?? String(localized: "알 수 없음"))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .reazyFont(.h3)
                            .foregroundStyle(.gray900)
                        
                        Text("마지막 수정 : \(pdfInfoMenuViewModel.timeAgoString(from: pdfSharedData.paperInfo!.lastModifiedDate))")
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
            .popover(isPresented: $pdfInfoMenuViewModel.isActivityViewPresented) {
                ActivityViewController(activityItems: [pdfInfoMenuViewModel.fileURL])
            }
            
            VStack(spacing: 10) {
                Button(action: {
                    self.mainPDFViewModel.isMenuSelected = false
                    homeViewModel.viewStatus = .search(pdfSharedData.paperInfo!)
                }, label: {
                    HStack{
                        Text("제목 수정")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(.editpencil)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                .padding(.top, 12)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    self.isStarSelected.toggle()
                    PDFSharedData.shared.paperInfo?.isFavorite = isStarSelected
                }, label: {
                    HStack{
                        Text("즐겨찾기")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(isStarSelected ? .starfill : .star)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(action: {
                    self.mainPDFViewModel.isMenuSelected = false
                    homeViewModel.isMovingFolder = true
                }, label: {
                    HStack{
                        Text("이동")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(.move)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                            .padding(.trailing, 14)
                    }
                })
                .foregroundStyle(.gray800)
                
                Divider()
                    .tint(.primary2)
                    .frame(height: 1)
                
                Button(role: .destructive, action: {
                    self.mainPDFViewModel.isMenuSelected = false
                    navigationCoordinator.pop()
                    self.homeViewModel.deletePDF(at: pdfSharedData.paperInfo?.id ?? UUID())
                }, label: {
                    HStack{
                        Text("삭제")
                            .reazyFont(.body1)
                            .padding(.leading, 12)
                        Spacer()
                        Image(.trash)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
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
        .onAppear {
            self.title = pdfSharedData.paperInfo?.title ?? "알 수 없음"
        }
        .onDisappear {
            homeViewModel.changedTitle = nil
        }
    }
}

#Preview {
    PDFInfoMenu(
        title: "Reazy",
        isStarSelected: false
    )
}
