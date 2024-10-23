import SwiftUI
import PDFKit

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀

struct TableCell: View {
    @EnvironmentObject var viewModel: OriginalViewModel
    @State var item: TableItem
    
    var body: some View {
        VStack(alignment: .leading){
            if item.children.isEmpty {
                HStack{
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.h3)
                        .foregroundStyle(.gray900)
                    //.padding(.vertical, 28)
                }
                .padding(.vertical, 11)
                .padding(.leading, 12)
            } else {
                HStack{
                    Button(action: {
                        item.isExpanded.toggle()
                    }, label: {
                        if !item.children.isEmpty {
                            Image(systemName: item.isExpanded ? "chevron.down" : "chevron.forward")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray800)
                        }
                    })
                    .padding(.trailing, 4)
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.h3)
                        .foregroundStyle(.gray900)
                }
                .padding(.vertical, 11)
                .padding(.leading, 12)
                .animation(.easeInOut(duration: 0.3), value: item.isExpanded)
                
                if item.isExpanded {
                    ForEach(item.children, id: \.id) { model in
                        HStack(spacing: 0){
                            Spacer().frame(width: 32, height: 0)
                            TableCell(item: model)
                        }
                        .padding(0)
                    }
                }
            }
            Spacer().frame(height: 5)
        }
    }
}

