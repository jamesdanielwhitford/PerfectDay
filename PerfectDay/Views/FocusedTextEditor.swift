import SwiftUI
import UIKit

struct FocusedTextEditor: UIViewRepresentable {
    @Binding var text: String
    var isFirstResponder: Bool

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FocusedTextEditor

        init(_ parent: FocusedTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
}
