import SwiftUI

struct QuickCaptureView: View {
    @Binding var text: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    let targetInfo: String
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "C46849"))
                    .font(.system(size: 16))
                Text("Quick Capture")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
                Text(targetInfo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            HStack {
                TextField("Capture a thought...", text: $text)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .scaleEffect(isSubmitting ? 0.98 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isSubmitting)
                    .onSubmit {
                        handleSubmit()
                    }
                
                if showSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .foregroundColor(.white.opacity(0.7))
                .keyboardShortcut(.escape)
                
                Button("Add") {
                    handleSubmit()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "C46849"))
                .keyboardShortcut(.return)
            }
        }
        .padding(16)
        .frame(width: 400, height: 140)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.2), value: showSuccess)
    }
    
    private func handleSubmit() {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onCancel()
            return
        }
        isSubmitting = true
        onSubmit()
        withAnimation {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showSuccess = false
        }
    }
}

class QuickCaptureHostingView: NSHostingView<QuickCaptureView> {
    private let onSubmit: (String) -> Void
    private let onCancel: () -> Void
    
    required init(rootView: QuickCaptureView) {
        self.onSubmit = { _ in }
        self.onCancel = { }
        super.init(rootView: rootView)
    }
    
    init(onSubmit: @escaping (String) -> Void, onCancel: @escaping () -> Void, targetInfo: String) {
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        
        var textValue: String = ""
        let textBinding = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )
        
        let view = QuickCaptureView(
            text: textBinding,
            onSubmit: {
                onSubmit(textValue)
            },
            onCancel: onCancel,
            targetInfo: targetInfo
        )
        super.init(rootView: view)
    }
    
    @MainActor required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
