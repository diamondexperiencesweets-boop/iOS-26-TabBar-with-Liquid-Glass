# NavigationTabBar

Custom floating tab bar with Liquid Glass effect for iOS 26+. Features an animated lens indicator, morphing search panel, and flexible alignment modes.

## Features

- Liquid Glass effect — translucent glass material with .glassEffect() from iOS 26
- Animated lens indicator — interactive LiquidLensView that follows drag gesture between tabs
- Search mode — panel smoothly morphs into a search field with text input
- Three alignment modes — center, panel left + search right, search left + panel right
- Adaptive layout — horizontal scroll when tabs overflow, drag-to-switch when they fit
- Customizable — tab icons, colors, active colors, screens per tab
- iOS 26+ — uses private _UILiquidLensView and UIViewRepresentable bridge

## Requirements

- iOS 26.0+
- Xcode 26+
- Swift 6

## Installation

1. Clone the repository
2. Add GlassTabBar.swift, LiquidLensView.swift, LiquidLensRepresentable.swift, HexColor.swift to your project
3. Add NavigationBarCode.swift if you want to display the source code in-app

## Usage

### Basic Tab Bar

import SwiftUI

enum AppTab {
    case home, chats, settings
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            currentScreen
            
            VStack {
                Spacer()
                GlassTabBar(
                    selectedTab: $selectedTab,
                    searchText: $searchText,
                    showSearch: true,
                    alignment: .center,
                    searchAction: { query in
                        print("Search: \(query)")
                    }
                ) {
                    TabItem(icon: "house.fill", color: .white, activeColor: .blue, title: "Home", tab: .home) {
                        HomeScreen()
                    }
                    TabItem(icon: "message.fill", color: .white, activeColor: .green, title: "Chats", tab: .chats) {
                        ChatsScreen()
                    }
                    TabItem(icon: "gear", color: .white, activeColor: .orange, title: "Settings", tab: .settings) {
                        SettingsScreen()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home: HomeScreen()
        case .chats: ChatsScreen()
        case .settings: SettingsScreen()
        }
    }
}

### Alignment Modes

// Center (default) — panel and search button centered
GlassTabBar(..., alignment: .center) { ... }

// Panel left, search right
GlassTabBar(..., alignment: .panelLeftSearchRight) { ... }

// Search left, panel right
GlassTabBar(..., alignment: .searchLeftPanelRight) { ... }

### TabItem Parameters

TabItem(
    icon: "house.fill",           // SF Symbol name
    color: .white,                // Inactive color
    activeColor: .blue,           // Active color (when lens is over)
    title: "Home",                // Tab title
    tab: .home                    // Your AppTab enum value
) {
    HomeScreen()                  // Screen view
}

### Search Mode

When the search button is tapped:
- The panel morphs into a search field with placeholder text
- The lens button becomes an X (clear) or magnifying glass (search)
- Typing text and pressing search triggers searchAction
- The search text is accessible via $searchText binding

GlassTabBar(
    selectedTab: $selectedTab,
    searchText: $searchText,
    searchAction: { query in
        performSearch(query)
    }
) { ... }

### Adaptive Scrolling

- When tabs fit the screen width — drag gesture moves the lens between tabs
- When tabs overflow — horizontal scroll with tap to select, no drag

### Hide Search Button

GlassTabBar(..., showSearch: false) { ... }

## File Structure

- GlassTabBar.swift — Main tab bar component with all logic
- LiquidLensView.swift — UIKit lens view implementation
- LiquidLensRepresentable.swift — UIViewRepresentable wrappers
- HexColor.swift — Color extension for hex strings
- ContentView.swift — Demo implementation
- NavigationBarCode.swift — Source code string for in-app display

## License

MIT License — see LICENSE file for details.
