import SwiftUI

struct ResizableSplitView<Left: View, Right: View>: View {
    let left: Left
    let right: Right
    @Binding var rightWidth: Double

    init(rightWidth: Binding<Double>, @ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self._rightWidth = rightWidth
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack(spacing: 0) {
            left
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            right
                .frame(width: rightWidth)
                .frame(maxHeight: .infinity)
        }
    }
}
