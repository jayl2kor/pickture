import SwiftUI
import UIKit

@main
struct PicktureApp: App {
    init() {
        let bgColor = UIColor(red: 1.0, green: 0.97, blue: 0.95, alpha: 1)
        UIWindow.appearance().backgroundColor = bgColor
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
