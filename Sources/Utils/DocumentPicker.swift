import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// 文件选择器（UIKit 原生包装）
/// SwiftUI 的 fileImporter 在部分 iOS 版本存在「能打开但无法选中文件」的问题，
/// 这里直接用 UIDocumentPickerViewController：
///   - asCopy: true：所选文件会被复制进 App 沙盒，读取无需安全作用域访问；
///   - allowedContentTypes 放宽为 .data：任意文件都可选，格式由导入方校验。
struct DocumentPicker: UIViewControllerRepresentable {
    var allowedContentTypes: [UTType] = [.data]
    var onPicked: (URL) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let parent: DocumentPicker
        init(parent: DocumentPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPicked(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}
