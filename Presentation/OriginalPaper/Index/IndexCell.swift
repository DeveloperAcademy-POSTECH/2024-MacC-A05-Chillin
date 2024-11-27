import SwiftUI
import PDFKit

// MARK: - 쿠로꺼 : TableView 커스텀 리스트 셀

struct IndexCell: View {
    @EnvironmentObject private var indexViewModel: IndexViewModel
    
    @State var item: TableItem
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(alignment: .leading){
            if item.children.isEmpty {
                HStack{
                    //들여쓰기
                    Spacer().frame(width: CGFloat(22 * item.level), height: 0)
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.button5)
                        .foregroundStyle(.gray900)
                }
                .padding(.leading, 30)
                .padding(.trailing, 9)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    Spacer().frame(width: CGFloat(22 * item.level), height: 0)
                    Button(action: {
                        withAnimation(.smooth(duration: 0.5)) {
                            item.isExpanded.toggle()
                        }
                    }, label: {
                        if !item.children.isEmpty {
                            VStack(alignment: .leading){
                                Image(systemName:  "chevron.forward" )
                                    .rotationEffect(.degrees(item.isExpanded ? 90 : 0))
                                    .animation(.smooth, value: item.isExpanded)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.gray800)
                            }
                        }
                    })
                    .padding(.trailing, 8)
                    
                    Text(item.table.label ?? "none")
                        .lineLimit(1)
                        .reazyFont(.button5)
                        .foregroundStyle(.gray900)
                }
                .padding(.trailing, 9)
                .padding(.leading, 4)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background{
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(selectedID == item.id ? Color(.primary2) : Color.clear)
                }
                .onTapGesture {
                    onTap()
                }
                if item.isExpanded {
                    ForEach(item.children, id: \.id) { item in
                        IndexCell(item: item, selectedID: $selectedID)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            Spacer().frame(height: 5)
        }
    }
    
    private func onTap() {
        if selectedID != item.id {
            selectedID = item.id
        }
        
        if let destination = item.table.destination {
            self.indexViewModel.selectedDestination = destination
        } else {
            print("No destination")
        }
    }
}
