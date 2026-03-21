import SwiftUI

struct ResizableSplitView<Left: View, Right: View>: View {
    let left: Left
    let right: Right
    @Binding var rightWidth: Double
    @State private var startWidth: Double = 0

    init(rightWidth: Binding<Double>, @ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self._rightWidth = rightWidth
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack(spacing: 0) {
            left
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 6)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if startWidth == 0 {
                                startWidth = rightWidth
                            }
                            rightWidth = max(340, startWidth - value.translation.width)
                        }
                        .onEnded { _ in
                            startWidth = 0
                        }
                )

            right
                .frame(width: rightWidth)
                .frame(maxHeight: .infinity)
        }
    }
}
