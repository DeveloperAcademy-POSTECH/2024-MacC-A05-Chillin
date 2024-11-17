//
//  MenuView.swift
//  Reazy
//
//  Created by 유지수 on 11/17/24.
//

import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var mainPDFViewModel: MainPDFViewModel
    @State private var selectedTab: String = "개요"
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                TabButton(title: "개요", selectedTab: $selectedTab)
                TabButton(title: "페이지", selectedTab: $selectedTab)
            }
            
            if selectedTab == "개요" {
                TableView()
                    .environmentObject(mainPDFViewModel)
            } else {
                PageView()
                    .environmentObject(mainPDFViewModel)
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
                    .frame(width: 126, height: 36)
                
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
