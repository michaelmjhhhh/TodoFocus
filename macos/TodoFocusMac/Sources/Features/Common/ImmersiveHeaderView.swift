import SwiftUI

@available(macOS 14.0, *)
struct ImmersiveHeaderView: View {
    @Binding var isExpanded: Bool
    @Binding var isSidebarVisible: Bool

    var body: some View {
        HStack(spacing: 0) {
            branding
                .frame(maxWidth: .infinity, alignment: .leading)

            sidebarToggle
        }
        .padding(.horizontal, 16)
        .frame(height: 32)
        .opacity(isExpanded ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }

    private var branding: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VisualTokens.accentTerracotta)

            Text("TodoFocus.")
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(VisualTokens.textSecondary)
        }
    }

    private var sidebarToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSidebarVisible.toggle()
            }
        } label: {
            Image(systemName: isSidebarVisible ? "sidebar.leading" : "sidebar.trailing")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(VisualTokens.textSecondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .opacity(isExpanded ? 1 : 0)
    }
}

struct ImmersiveHeaderModifier: ViewModifier {
    @Binding var isExpanded: Bool
    @Binding var isSidebarVisible: Bool

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            ImmersiveHeaderView(isExpanded: $isExpanded, isSidebarVisible: $isSidebarVisible)
                .padding(.top, 6)

            content
        }
    }
}

extension View {
    func immersiveHeader(isExpanded: Binding<Bool>, isSidebarVisible: Binding<Bool>) -> some View {
        modifier(ImmersiveHeaderModifier(isExpanded: isExpanded, isSidebarVisible: isSidebarVisible))
    }
}
