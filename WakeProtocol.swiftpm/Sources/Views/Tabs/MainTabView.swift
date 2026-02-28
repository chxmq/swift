import SwiftUI
import UIKit

/// Main tab navigation — Alarms, Learn, About
struct MainTabView: View {
    var store: AlarmStore

    @State private var selectedTab = 0

    private static func separatorImage(uiColor: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            uiColor.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            AlarmListView(store: store)
                .tag(0)
                .tabItem {
                    Label("Alarms", systemImage: "alarm.fill")
                }

            LearnView()
                .tag(1)
                .tabItem {
                    Label("Learn", systemImage: "brain.head.profile")
                }

            AboutView()
                .tag(2)
                .tabItem {
                    Label("About", systemImage: "info.circle.fill")
                }
        }
        .tint(Theme.primaryAccent)
        .preferredColorScheme(.light)
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithOpaqueBackground()
            tabBarAppearance.backgroundColor = UIColor(Theme.surface)
            tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.primaryAccent)
            tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.primaryAccent)
            ]
            tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.textTertiary)
            tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.textTertiary)
            ]
            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
            navAppearance.backgroundColor = UIColor(Theme.surfaceElevated)
            navAppearance.shadowColor = UIColor(Theme.oliveLeaf).withAlphaComponent(0.35)
            navAppearance.shadowImage = Self.separatorImage(uiColor: UIColor(Theme.oliveLeaf).withAlphaComponent(0.35))
            navAppearance.titlePositionAdjustment = .zero
            let titleFont = UIFont.systemFont(ofSize: 34, weight: .bold)
            let inlineFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
            navAppearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor(Theme.textPrimary),
                .font: titleFont
            ]
            navAppearance.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.textPrimary),
                .font: inlineFont
            ]
            navAppearance.buttonAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(Theme.primaryAccent)
            ]
            UINavigationBar.appearance().standardAppearance = navAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            UINavigationBar.appearance().compactAppearance = navAppearance
            UINavigationBar.appearance().tintColor = UIColor(Theme.primaryAccent)
        }
    }
}
