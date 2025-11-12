
//  MenuView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State private var selectedTab: String = String(localized: "목차")

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(title: String(localized: "목차"), selectedTab: $selectedTab)
                TabButton(title: String(localized: "페이지"), selectedTab: $selectedTab)
                TabButton(title: String(localized: "주석"), selectedTab: $selectedTab)
            }

            switch selectedTab {
            case String(localized: "목차"):
                IndexView()
            case String(localized: "페이지"):
                PageListView()
            case String(localized: "주석"):
                AnnotationCollectionView()
            default:
                EmptyView()
            }
        }
    }
}

struct TabButton: View {
    let title: String
    @Binding var selectedTab: String

    var body: some View {
        Button(action: {
            withAnimation {
                selectedTab = title
            }
        }) {
            VStack(spacing: 0) {
                Text(title)
                    .reazyFont(selectedTab == title ? .body3 : .text5)
                    .foregroundStyle(selectedTab == title ? .primary1 : .gray600)
                    .frame(width: 84, height: 36)

                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(selectedTab == title ? .primary1 : .primary3)
            }
        }
    }
}

#Preview {
    MenuView()
}
