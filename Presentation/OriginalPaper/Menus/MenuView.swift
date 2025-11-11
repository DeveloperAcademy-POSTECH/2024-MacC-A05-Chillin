
//  MenuView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State private var selectedTab: MenuTap = .contents

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(currentTap: .contents, selectedTab: $selectedTab)
                TabButton(currentTap: .pages, selectedTab: $selectedTab)
                TabButton(currentTap: .annotation, selectedTab: $selectedTab)
            }
            switch selectedTab {
            case .contents:
                IndexView()
            case .pages:
                PageListView()
            case .annotation:
                AnnotationCollectionView()
            }
        }
    }
}

struct TabButton: View {
    private let currentTap: MenuTap
    @Binding private var selectedTab: MenuTap
    
    fileprivate init(
        currentTap: MenuTap,
        selectedTab: Binding<MenuTap>
    ) {
        self.currentTap = currentTap
        self._selectedTab = selectedTab
    }

    var body: some View {
        Button(action: {
            withAnimation {
                selectedTab = currentTap
            }
        }) {
            VStack(spacing: 0) {
                Text(currentTap.title)
                    .reazyFont(selectedTab == currentTap ? .body3 : .text5)
                    .foregroundStyle(selectedTab == currentTap ? .primary1 : .gray600)
                    .frame(width: 84, height: 36)

                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(selectedTab == currentTap ? .primary1 : .primary3)
            }
        }
    }
}

private enum MenuTap {
    case contents
    case pages
    case annotation
    
    public var title: String {
        switch self {
        case .contents:
            String(localized: "목차")
        case .pages:
            String(localized: "페이지")
        case .annotation:
            String(localized: "주석")
        }
    }
}

#Preview {
    MenuView()
}
