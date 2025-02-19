//
//  Component.swift
//  Reazy
//
//  Created by 김예림 on 2/17/25.
//

import SwiftUI

struct EllipsisView: View {
    let ellipsisAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            Button {
                ellipsisAction()
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 24))
                    .foregroundStyle(.gray550)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 20)
        }
    }
}

