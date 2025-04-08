//
//  TagControlView.swift
//  Reazy
//
//  Created by 문인범 on 3/6/25.
//

import SwiftUI


/**
 태그 관리 뷰
 */
struct TagControlView: View {
    @StateObject private var viewModel: TagControlViewModel = .init(
        useCase: DefaultTagControlUseCase(
            paperDataRepository: PaperDataRepositoryImpl(),
            tagRepository: TagDataRepositoryImpl()
        )
    )
    
    @FocusState private var textFieldFocus: Bool
    @State var paperInfo: PaperInfo
    
    let cancelAction: () -> Void
    let completeAction: () -> Void
    
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            if viewModel.isOverMaximumTagAlertPresented {
                OverMaximumTagAlertView {
                    viewModel.isOverMaximumTagAlertPresented = false
                }
            } else {
                HStack(alignment: .top, spacing: 40) {
                    Image(uiImage: .init(data: paperInfo.thumbnail) ?? .testThumbnail)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                    
                    VStack(spacing: 0) {
                        TagInputTextField(
                            viewModel: viewModel,
                            paperInfo: $paperInfo,
                            textFieldFocus: $textFieldFocus
                        )
                        
                        ZStack(alignment: .top) {
                            VStack {
                                Text("태그를 만들거나 추가할 태그를 검색하세요")
                                    .reazyFont(.text1)
                                    .foregroundStyle(.comment)
                                    .padding(.top, 14)
                                    .padding(.bottom, 20)
                                
                                ForEach(paperInfo.tags) { tag in
                                    IncludedTagView(tag: tag) {
                                        viewModel.deleteTagButtonTapped(paperId: paperInfo.id, tag: tag)
                                        paperInfo.tags.removeAll { $0.id == tag.id }
                                    }
                                }
                            }
                            
                            if textFieldFocus {
                                NewTagSearchResultView(
                                    viewModel: viewModel,
                                    paperInfo: $paperInfo,
                                    textFieldFocus: $textFieldFocus
                                )
                            }
                        }
                        .animation(.easeInOut, value: textFieldFocus)
                    }
                }
            }
        }
        .onTapGesture {
            textFieldFocus = false
        }
        .overlay(alignment: .top) {
            HStack {
                Button {
                    cancelAction()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray100)
                }
                .padding(.top, 28)
                
                Spacer()
                
                Button {
                    completeAction()
                } label: {
                    ZStack {
                        Capsule()
                            .stroke(lineWidth: 1)
                            .foregroundStyle(.gray100)
                            .frame(width: 68, height: 36)
                        
                        Text("완료")
                            .reazyFont(.text1)
                            .foregroundStyle(.gray100)
                    }
                }
                .padding(.top, 22)
            }
            .padding(.horizontal, 28)
        }
        .animation(.easeInOut, value: viewModel.isOverMaximumTagAlertPresented)
    }
}


/// 태그 검색 TextField
private struct TagInputTextField: View {
    @ObservedObject var viewModel: TagControlViewModel
    
    @Binding var paperInfo: PaperInfo
    var textFieldFocus: FocusState<Bool>.Binding
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.gray100)
            
            
            RoundedRectangle(cornerRadius: 12)
                .stroke(lineWidth: 1)
                .foregroundStyle(.gray400)
            
            HStack(spacing: 0) {
                TextField("새로운 태그", text: $viewModel.searchText)
                    .focused(textFieldFocus)
                    .reazyFont(.text1)
                    .foregroundStyle(.gray800)
                    .lineLimit(1)
                    .onSubmit {
                        if let tag = viewModel.onSubmit(paperInfo: paperInfo) {
                            self.paperInfo.tags.append(tag)
                        }
                        textFieldFocus.wrappedValue = false
                    }
                
                Button {
                    if let tag = viewModel.onSubmit(paperInfo: paperInfo) {
                        self.paperInfo.tags.append(tag)
                    }
                    textFieldFocus.wrappedValue = false
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary1)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
        }
        .frame(width: 400, height: 52)
        .onChange(of: viewModel.searchText) { _, newValue in
            if newValue.count > 30 {
                viewModel.searchText = String(newValue.prefix(30))
            }
            viewModel.searchTagButtonTapped()
        }
    }
}


/// 현재 Paperinfo에 추가되어 있는 태그를 보여주는 뷰
private struct IncludedTagView: View {
    let tag: Tag
    let action: () -> Void
    
    var body: some View {
        Group {
            HStack(spacing: 0) {
                TagControlCell(name: tag.name)
                    .disabled(true)
                
                Spacer()
                
                Button {
                    action()
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray100)
                }
            }
            .padding(.leading, 8)
            .padding(.trailing, 16)
        }
        .frame(width: 400)
        .padding(.bottom, 12)
    }
}


/// 검색 결과를 보여주는 뷰
private struct NewTagSearchResultView: View {
    @ObservedObject var viewModel: TagControlViewModel
    
    @Binding var paperInfo: PaperInfo
    var textFieldFocus: FocusState<Bool>.Binding
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.gray200)
            
            if viewModel.showingSearchPlaceholder {
                Text(
                """
                새로운 태그를 만들거나
                추가할 태그를 검색하세요
                최대 30자
                """
                )
                .reazyFont(.body1)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray600)
            }
            
            
            
            ScrollView {
                Group {
                    if viewModel.showingCreateNewTag {
                        CreateNewTagCell(name: viewModel.searchText) {
                            if let tag = viewModel.onSubmit(paperInfo: paperInfo) {
                                paperInfo.tags.append(tag)
                            }
                            textFieldFocus.wrappedValue = false
                        }
                    }
                    
                    VStack {
                        if viewModel.showingExistingTags {
                            ForEach(viewModel.searchedTags) { tag in
                                HStack {
                                    TagControlCell(tag: tag) {
                                        if let tag = viewModel.existingTagTapped(paperInfo: paperInfo, tag: tag) {
                                            self.paperInfo.tags.append(tag)
                                        }
                                        textFieldFocus.wrappedValue = false
                                    }
                                    
                                    Spacer()
                                }
                            }
                        } else if viewModel.showingRecentAddedTags {
                            ForEach(viewModel.recentAddedTags) { tag in
                                HStack {
                                    TagControlCell(tag: tag) {
                                        if let tag = viewModel.existingTagTapped(paperInfo: paperInfo, tag: tag) {
                                            self.paperInfo.tags.append(tag)
                                        }
                                        textFieldFocus.wrappedValue = false
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 18)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .frame(width: 400, height: 240)
    }
}


/// 검새결과 내 새로운 태그 생성을 나타내는 셀
private struct CreateNewTagCell: View {
    let name: String
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Text("생성")
                    .reazyFont(.body1)
                    .foregroundStyle(.gray600)
                
                TagControlCell(name: name)
                    .disabled(true)
                
                Spacer()
            }
        }
    }
}


private struct OverMaximumTagAlertView: View {
    let action: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray200)
            
            VStack(spacing: 0) {
                Text("태그는 최대 7개까지 추가할 수 있어요.\n새 태그를 추가하려면 기존 태그를 삭제해주세요.")
                    .font(.custom("Pretendard-SemiBold", size: 16))
                    .multilineTextAlignment(.center)
                    .frame(height: 106)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(hex: "D9DBE9"))
                
                Button {
                    action()
                } label: {
                    Text("확인")
                        .font(.custom("Pretendard-Medium", size: 16))
                        .foregroundStyle(.primary1)
                        .frame(width: 364, height: 57)
                }
            }
        }
        .frame(width: 364, height: 163)
    }
}
