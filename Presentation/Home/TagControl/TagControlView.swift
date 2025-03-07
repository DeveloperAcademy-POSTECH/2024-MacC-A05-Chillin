//
//  TagControlView.swift
//  Reazy
//
//  Created by 문인범 on 3/6/25.
//

import SwiftUI



struct TagControlView: View {
    @StateObject private var viewModel: TagControlViewModel = .init(
        useCase: DefaultTagControlUseCase(
            paperDataRepository: PaperDataRepositoryImpl(),
            tagRepository: TagDataRepositoryImpl()
        )
    )
    
    @FocusState private var textFieldFocus: Bool
    
    
    var body: some View {
        ZStack {
            HStack(alignment: .top, spacing: 40) {
                Image(.testThumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                
                VStack(spacing: 0) {
                    TagInputTextField(
                        viewModel: viewModel,
                        textFieldFocus: $textFieldFocus
                    )
                    
                    ZStack(alignment: .top) {
                        VStack {
                            Text("태그를 만들거나 추가할 태그를 검색하세요")
                                .reazyFont(.text1)
                                .foregroundStyle(.comment)
                                .padding(.top, 14)
                                .padding(.bottom, 20)
                            
                            ForEach(0 ..< 7) { _ in
                                IncludedTagView()
                            }
                        }
                        
                        if textFieldFocus {
                            NewTagSearchResultView(viewModel: viewModel)
                        }
                    }
                    .animation(.easeInOut, value: textFieldFocus)
                }
            }
        }
    }
}




private struct TagInputTextField: View {
    @ObservedObject var viewModel: TagControlViewModel
    
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
                        
                    }
                
                Button {
                    textFieldFocus.wrappedValue.toggle()
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
        .onReceive(viewModel.$searchText) { _ in
            viewModel.searchTagButtonTapped()
        }
    }
}


private struct IncludedTagView: View {
    var body: some View {
        Group {
            HStack(spacing: 0) {
                TagControlCell(name: "테스트 태그")
                
                Spacer()
                
                Button {
                    
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


private struct NewTagSearchResultView: View {
    @ObservedObject var viewModel: TagControlViewModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .foregroundStyle(.gray200)
            
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
            .opacity( viewModel.showingSearchPlaceholder ? 1 : 0 )
            
            
            
            ScrollView {
                Group {
                    if viewModel.showingCreateNewTag {
                        CreateNewTagCell(name: viewModel.searchText)
                    }
                    
                    if viewModel.showingExistingTags {
                        VStack {
                            ForEach(viewModel.searchedTags) { tag in
                                HStack {
                                    TagControlCell(name: tag.name)
                                    
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

private struct CreateNewTagCell: View {
    let name: String
    
    var body: some View {
        Button {
            
        } label: {
            HStack(spacing: 8) {
                Text("생성")
                    .reazyFont(.body1)
                    .foregroundStyle(.gray600)
                
                TagControlCell(name: name)
                
                Spacer()
            }
        }
    }
}
