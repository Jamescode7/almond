import SwiftUI
import Combine

final class DocumentViewState: ObservableObject {
    @Published var zoomPercent: Int = 100
    @Published var appearanceOverride: AppearanceMode = .system
    @Published var scrollPercent: Double = 0
    @Published var showSearch: Bool = false
    @Published var searchQuery: String = ""

    private static let zoomStep: Int = 10
    private static let zoomMin: Int = 80
    private static let zoomMax: Int = 200

    func zoomIn() {
        zoomPercent = min(Self.zoomMax, zoomPercent + Self.zoomStep)
    }

    func zoomOut() {
        zoomPercent = max(Self.zoomMin, zoomPercent - Self.zoomStep)
    }

    func zoomReset() {
        zoomPercent = 100
    }

    func cycleAppearance() {
        appearanceOverride = appearanceOverride.next()
    }
}
