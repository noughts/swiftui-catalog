//
//  SheetCatalogView.swift
//  SwiftUI Catalog
//
//  Created by Koichi Yamamoto on 2026/10/20.
//

import SwiftUI

struct SheetCatalogView: View {
    @State private var options = SheetOptions()
    @State private var selectedDetentOption: DetentOption?
    @State private var isSheetPresented = false
    @State private var isFullScreenCoverPresented = false
    @State private var dismissCount = 0

    var body: some View {
        Form {
            Section {
                Button("sheet を表示") {
                    selectedDetentOption = nil
                    isSheetPresented = true
                }
                Button("fullScreenCover を表示") {
                    isFullScreenCoverPresented = true
                }
                LabeledContent("onDismiss 回数", value: dismissCount, format: .number)
            }

            Section {
                ForEach(DetentOption.allCases) { option in
                    Toggle(option.title, isOn: isEnabled(option))
                }
            } header: {
                Text("presentationDetents")
            } footer: {
                Text("すべてオフの場合は large のみ。一番小さい detent で表示を開始します。")
            }

            Section {
                Picker("presentationDragIndicator", selection: $options.dragIndicator) {
                    Text("automatic").tag(Visibility.automatic)
                    Text("visible").tag(Visibility.visible)
                    Text("hidden").tag(Visibility.hidden)
                }
                Toggle("interactiveDismissDisabled", isOn: $options.isInteractiveDismissDisabled)
            } footer: {
                Text("interactiveDismissDisabled をオンにすると、スワイプや背面タップでは閉じられなくなります。")
            }

            Section {
                Picker("presentationBackgroundInteraction", selection: $options.backgroundInteraction) {
                    ForEach(BackgroundInteractionOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } footer: {
                Text("enabled にすると sheet 表示中もこの画面を操作でき、設定変更が sheet に即時反映されます。")
            }

            Section {
                Picker("presentationContentInteraction", selection: $options.contentInteraction) {
                    ForEach(ContentInteractionOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } footer: {
                Text("detent が複数あるとき、sheet 内のスワイプでサイズ変更とスクロールのどちらを優先するか。")
            }

            Section("presentationCornerRadius") {
                Toggle("角丸を指定", isOn: $options.usesCustomCornerRadius)
                if options.usesCustomCornerRadius {
                    LabeledContent("半径", value: options.customCornerRadius, format: .number)
                    Slider(value: $options.customCornerRadius, in: 0...60, step: 1)
                }
            }
        }
        .navigationTitle("Sheet")
        .sheet(isPresented: $isSheetPresented, onDismiss: { dismissCount += 1 }) {
            PresentedSheetCatalog(detentOptions: options.enabledDetents, selectedDetent: selectedDetent)
                .presentationDetents(Set(options.enabledDetents.map(\.detent)), selection: selectedDetent)
                .presentationDragIndicator(options.dragIndicator)
                .interactiveDismissDisabled(options.isInteractiveDismissDisabled)
                .presentationBackgroundInteraction(options.backgroundInteraction.interaction)
                .presentationContentInteraction(options.contentInteraction.interaction)
                .presentationCornerRadius(options.cornerRadius)
        }
        .fullScreenCover(isPresented: $isFullScreenCoverPresented, onDismiss: { dismissCount += 1 }) {
            PresentedSheetCatalog(detentOptions: [], selectedDetent: .constant(.large))
        }
    }

    /// 有効な detent に含まれる値だけを返す selection。
    /// 含まれない detent を selection に渡すと SwiftUI が Invalid Configuration を出すため。
    private var selectedDetent: Binding<PresentationDetent> {
        Binding {
            options.resolvedDetent(for: selectedDetentOption).detent
        } set: { detent in
            selectedDetentOption = DetentOption.allCases.first { $0.detent == detent }
        }
    }

    private func isEnabled(_ option: DetentOption) -> Binding<Bool> {
        Binding {
            options.detents.contains(option)
        } set: { isOn in
            if isOn {
                options.detents.insert(option)
            } else {
                options.detents.remove(option)
            }
        }
    }
}

/// 表示した sheet の中で SheetCatalogView を再帰的に表示し、次の sheet の設定を階層ごとに変えられるようにする
private struct PresentedSheetCatalog: View {
    let detentOptions: [DetentOption]
    @Binding var selectedDetent: PresentationDetent

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SheetCatalogView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if detentOptions.count > 1 {
                        ToolbarItem(placement: .topBarLeading) {
                            Picker("selection", selection: $selectedDetent) {
                                ForEach(detentOptions) { option in
                                    Text(option.title).tag(option.detent)
                                }
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct SheetOptions {
    var detents: Set<DetentOption> = [.medium, .large]
    var dragIndicator: Visibility = .automatic
    var isInteractiveDismissDisabled = false
    var backgroundInteraction: BackgroundInteractionOption = .automatic
    var contentInteraction: ContentInteractionOption = .automatic
    var usesCustomCornerRadius = false
    var customCornerRadius: Double = 24

    /// 小さい順に並べた有効な detent。空の場合は large のみ。
    var enabledDetents: [DetentOption] {
        let enabled = DetentOption.allCases.filter { detents.contains($0) }
        return enabled.isEmpty ? [.large] : enabled
    }

    /// selection が有効な detent に含まれない（未選択を含む）場合は一番小さい detent を返す。
    func resolvedDetent(for selection: DetentOption?) -> DetentOption {
        if let selection, enabledDetents.contains(selection) {
            return selection
        }
        return enabledDetents.first ?? .large
    }

    var cornerRadius: CGFloat? {
        usesCustomCornerRadius ? customCornerRadius : nil
    }
}

private enum DetentOption: CaseIterable, Identifiable {
    case height150
    case fraction30
    case medium
    case large

    var id: Self { self }

    var title: String {
        switch self {
        case .height150: ".height(150)"
        case .fraction30: ".fraction(0.3)"
        case .medium: ".medium"
        case .large: ".large"
        }
    }

    var detent: PresentationDetent {
        switch self {
        case .height150: .height(150)
        case .fraction30: .fraction(0.3)
        case .medium: .medium
        case .large: .large
        }
    }
}

private enum BackgroundInteractionOption: CaseIterable, Identifiable {
    case automatic
    case disabled
    case enabled
    case enabledUpThroughMedium

    var id: Self { self }

    var title: String {
        switch self {
        case .automatic: "automatic"
        case .disabled: "disabled"
        case .enabled: "enabled"
        case .enabledUpThroughMedium: "enabled(upThrough: .medium)"
        }
    }

    var interaction: PresentationBackgroundInteraction {
        switch self {
        case .automatic: .automatic
        case .disabled: .disabled
        case .enabled: .enabled
        case .enabledUpThroughMedium: .enabled(upThrough: .medium)
        }
    }
}

private enum ContentInteractionOption: CaseIterable, Identifiable {
    case automatic
    case resizes
    case scrolls

    var id: Self { self }

    var title: String {
        switch self {
        case .automatic: "automatic"
        case .resizes: "resizes"
        case .scrolls: "scrolls"
        }
    }

    var interaction: PresentationContentInteraction {
        switch self {
        case .automatic: .automatic
        case .resizes: .resizes
        case .scrolls: .scrolls
        }
    }
}

#Preview {
    NavigationStack {
        SheetCatalogView()
    }
}
