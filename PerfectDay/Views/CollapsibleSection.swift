import SwiftUI

struct CollapsibleSection<Content: View, Preview: View>: View {
    @Binding var isExpanded: Bool
    let title: String
    let content: Content
    let preview: Preview

    init(isExpanded: Binding<Bool>, title: String, @ViewBuilder content: () -> Content, @ViewBuilder preview: () -> Preview) {
        self._isExpanded = isExpanded
        self.title = title
        self.content = content()
        self.preview = preview()
    }

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.leading)
                Spacer()
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .padding(.trailing)
            }
            .padding(.top)
            
            if isExpanded {
                content
            } else {
                preview
                    .padding(.horizontal)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .padding([.horizontal, .top])
    }
}
