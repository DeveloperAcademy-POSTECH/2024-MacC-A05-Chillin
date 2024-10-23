import SwiftUI
import PDFKit

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀

struct Model: Identifiable {
    let id: UUID
    let title: String
    let children: [Model]
    var isExpanded: Bool
}



struct TableCell: View {
    @EnvironmentObject var viewModel: OriginalViewModel
    //    @State var isSelected: Bool = false
    //    @Binding var selectedID: UUID?
    @State var item: TableItem
    
    var body: some View {
        if item.children.isEmpty {
            VStack(alignment: .leading){
                Text(item.table.label ?? "none")
                    .lineLimit(1)
                    .reazyFont(.h3)
                    .foregroundStyle(.gray900)
                    .padding(.vertical, 4)
            }
        } else {
            VStack(alignment: .leading){
                HStack{
                    Button(action: {
                            item.isExpanded.toggle()
                    }, label: {
                        if !item.children.isEmpty {
                            Image(systemName: item.isExpanded ? "chevron.down" : "chevron.forward")
                                .foregroundStyle(.gray800)
                                .font(.system(size: 12))
                        }
                    })
                    Spacer().frame(width: 4)
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.h3)
                        .foregroundStyle(.gray900)
                        .padding(.vertical, 4)
                    
                }
                if item.isExpanded {
                    ForEach(item.children, id: \.id) { model in
                        HStack{
                            Spacer().frame(width: 32)
                            TableCell(item: model)
                        }
                    }
                }
            }
            //.transition(.move(edge: .top))
            .animation(.smooth(duration: 0.3), value: item.isExpanded)
        }
    }
}
//
//#Preview {
//    let model = Model(id: .init(), title: "1.Introduction", children: [
//        Model(id: .init(), title: "1.1. Contribution", children: [], isExpanded: false),
//        Model(id: .init(), title: "1.2. Organization", children: [
//            Model(id: .init(), title: "1.2.1 Organization", children: [], isExpanded: false)
//        ], isExpanded: false)
//    ], isExpanded: false)
//    
//    TableCell(item: model)
//}
