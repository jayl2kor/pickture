import SwiftUI
import UIKit

@main
struct PicktureApp: App {
    init() {
        // Set window background to match the app's dark gradient
        let bgColor = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1)
        UIWindow.appearance().backgroundColor = bgColor
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
