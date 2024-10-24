import SwiftUI
import PDFKit

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀

struct TableCell: View {
    
    @EnvironmentObject var viewModel: OriginalViewModel
    @State var item: TableItem
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(alignment: .leading){
            if item.children.isEmpty {
                HStack{
                    //들여쓰기
                    Spacer().frame(width: CGFloat(20 * item.level), height: 0)
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.h3)
                        .foregroundStyle(.gray900)
                }
                .padding(.vertical, 12)
                .padding(.leading, 12)
                //이렇게 너비를 지정하는 게 ㄱㅊ은지?
                .frame(width: 228, alignment: .leading)
                .background{
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(selectedID == item.id ? Color(.primary2) : Color.clear)
                }
                .onTapGesture {
                    onTap()
                }
            } else {
                HStack{
                    //들여쓰기
                    Spacer().frame(width: CGFloat(20 * item.level), height: 0)
                    Button(action: {
                        item.isExpanded.toggle()
                    }, label: {
                        if !item.children.isEmpty {
                            Image(systemName:  "chevron.forward" )
                                .rotationEffect(.degrees(item.isExpanded ? 90 : 0))
                                .animation(.smooth, value: item.isExpanded)
                                .font(.system(size: 11))
                                .foregroundStyle(.gray800)
                        }
                    })
                    .padding(.leading, 12)
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.h3)
                        .foregroundStyle(.gray900)
                }
                .padding(.vertical, 12)
                .frame(width: 228, alignment: .leading)
                .background{
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(selectedID == item.id ? Color(.primary2) : Color.clear)
                }
                .onTapGesture {
                    onTap()
                }
                if item.isExpanded {
                    ForEach(item.children, id: \.id) { item in
                        TableCell(item: item, selectedID: $selectedID)
                            .animation(.smooth(duration: 0.3), value: item.isExpanded)
                            .padding(0)
                    }
                }
            }
            Spacer().frame(height: 5)
        }
        //.transition(AnyTransition.opacity.animation(.default))
        //.animation(.smooth(duration: 0.3), value: item.isExpanded)
    }
    
    private func onTap() {
        if selectedID != item.id {
            selectedID = item.id
        }
        if let destination = item.table.destination {
            viewModel.selectedDestination = destination
            //test
            dump(destination)
        } else {
            print("No destination")
        }
    }
}
