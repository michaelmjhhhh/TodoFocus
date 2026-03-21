import SwiftUI

struct RootView: View {
    @Bindable var appModel: AppModel
    let databasePath: String

    var body: some View {
        ResizableSplitView(
            rightWidth: Binding(
                get: { appModel.detailPanelWidth },
                set: { (value: Double) in appModel.detailPanelWidth = value }
            )
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TodoFocus (SwiftUI Rewrite)")
                    .font(.title2.bold())
                Text("Issue #15 branch in progress")
                    .foregroundStyle(.secondary)
                Text("DB: \(databasePath)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } right: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Detail")
                    .font(.headline)
                Text("Placeholder panel")
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
