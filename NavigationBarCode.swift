//
//  NavigationBarCode.swift
//  NavigationTabBar1
//
//  Created by Павел Семин on 28.04.2026.
//

import Foundation

// MARK: - Navigation Bar Code

struct NavigationBarCode {
    static let code: String = """
    //
    //  GlassTabBar.swift
    //  NavigationTabBar1
    //
    //  Created by Павел Семин on 28.04.2026.
    //

    import SwiftUI

    // MARK: - GlassTabBarType

    enum GlassTabBarType {
        case simple
    }

    // MARK: - Tab Bar Lens

    struct TabBarLensWithMask: UIViewRepresentable {
        var width: CGFloat
        var height: CGFloat
        var isLifted: Bool
        
        func makeUIView(context: Context) -> LiquidLensView {
            let lensView = LiquidLensView(kind: .noContainer)
            lensView.backgroundColor = .clear
            return lensView
        }
        
        func updateUIView(_ uiView: LiquidLensView, context: Context) {
            let size = CGSize(width: width, height: height)
            
            let selectionSize = CGSize(
                width: size.width * 0.9,
                height: size.height * 0.85
            )
            let selectionOrigin = CGPoint(
                x: (size.width - selectionSize.width) / 2,
                y: (size.height - selectionSize.height) / 2
            )
            
            uiView.update(
                size: size,
                cornerRadius: size.height / 2,
                selectionOrigin: selectionOrigin,
                selectionSize: selectionSize,
                inset: -4.0,
                liftedInset: 4.0,
                isDark: false,
                isLifted: isLifted,
                isCollapsed: false,
                transition: .immediate
            )
        }
    }

    // MARK: - Tab Item View

    struct TabItemView: View {
        let icon: String
        let title: String
        let itemWidth: CGFloat
        let indicatorHeight: CGFloat
        let foregroundColor: Color
        
        var body: some View {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolVariant(.fill)
                
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: itemWidth, height: indicatorHeight)
            .foregroundStyle(foregroundColor)
        }
    }

    // MARK: - TabItem

    struct TabItem<Screen: View> {
        let icon: String
        let title: String
        let color: Color
        let activeColor: Color
        let tab: AppTab
        let screen: () -> Screen
        
        init(icon: String, color: Color, activeColor: Color, title: String, tab: AppTab, @ViewBuilder screen: @escaping () -> Screen) {
            self.icon = icon
            self.color = color
            self.activeColor = activeColor
            self.title = title
            self.tab = tab
            self.screen = screen
        }
    }

    // MARK: - GlassTabBar

    struct GlassTabBar<Screen: View>: View {
        private let type: GlassTabBarType
        private let items: [TabItem<Screen>]
        private let showSearch: Bool
        private let maxPanelWidth: CGFloat?
        
        @Binding private var selectedTab: AppTab
        @GestureState private var isActive: Bool = false
        @State private var isInitialOffsetSet: Bool = false
        @State private var dragOffset: CGFloat = 0
        @State private var lastDragOffset: CGFloat?
        
        private let panelPadding: CGFloat = 3
        private let minItemWidth: CGFloat = 60
        private let maxItemWidth: CGFloat = 90
        
        private var allItemsFit: Bool {
            let tabCount = items.count
            let screenWidth = UIScreen.main.bounds.width
            let searchReservedSpace: CGFloat = showSearch ? 72 : 0
            let availableWidth = screenWidth - 32 - searchReservedSpace
            let calculatedItemWidth = availableWidth / CGFloat(tabCount)
            return calculatedItemWidth >= minItemWidth
        }
        
        init(_ type: GlassTabBarType = .simple,
             selectedTab: Binding<AppTab>,
             showSearch: Bool = true,
             maxPanelWidth: CGFloat? = nil,
             @TabBarBuilder items: () -> [TabItem<Screen>]) {
            self.type = type
            self._selectedTab = selectedTab
            self.showSearch = showSearch
            self.maxPanelWidth = maxPanelWidth
            self.items = items()
        }
        
        private func indexForTab(_ tab: AppTab) -> Int {
            items.firstIndex(where: { $0.tab == tab }) ?? 0
        }
        
        var body: some View {
            GeometryReader { geometry in
                let totalWidth = geometry.size.width
                let tabCount = items.count
                let searchReservedSpace: CGFloat = showSearch ? 72 : 0
                let availableWidth = totalWidth - searchReservedSpace
                
                let calculatedItemWidth = availableWidth / CGFloat(tabCount)
                let needsScrolling = !allItemsFit
                
                let idealPanelWidth: CGFloat = needsScrolling
                    ? availableWidth
                    : max(min(calculatedItemWidth, maxItemWidth), minItemWidth) * CGFloat(tabCount)
                
                let panelWidth: CGFloat = {
                    if let maxWidth = maxPanelWidth {
                        return min(idealPanelWidth, maxWidth)
                    }
                    return idealPanelWidth
                }()
                
                let tabItemWidth: CGFloat = needsScrolling
                    ? max(calculatedItemWidth, minItemWidth)
                    : max(min(calculatedItemWidth, maxItemWidth), minItemWidth)
                
                let tabItemHeight: CGFloat = 56
                let totalContentWidth = tabItemWidth * CGFloat(tabCount)
                let maxDrag = totalContentWidth - tabItemWidth
                
                if isInitialOffsetSet {
                    HStack(spacing: 12) {
                        ZStack {
                            if needsScrolling {
                                ScrollViewReader { scrollProxy in
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        panelInnerContent(
                                            tabItemWidth: tabItemWidth,
                                            tabItemHeight: tabItemHeight,
                                            maxDrag: maxDrag,
                                            allowDrag: false
                                        )
                                        .frame(width: totalContentWidth)
                                        .id("panelContent")
                                    }
                                    .frame(width: panelWidth)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                                    .onChange(of: selectedTab) { _, newTab in
                                        let index = indexForTab(newTab)
                                        let targetOffset = CGFloat(index) * tabItemWidth
                                        withAnimation(.bouncy) {
                                            scrollProxy.scrollTo("panelContent", anchor: UnitPoint(x: targetOffset / totalContentWidth, y: 0.5))
                                        }
                                    }
                                }
                            } else {
                                panelInnerContent(
                                    tabItemWidth: tabItemWidth,
                                    tabItemHeight: tabItemHeight,
                                    maxDrag: maxDrag,
                                    allowDrag: true
                                )
                                .frame(width: panelWidth)
                            }
                        }
                        .frame(width: panelWidth, height: tabItemHeight + panelPadding * 2)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
                        
                        if showSearch {
                            Button {
                                // Поиск
                            } label: {
                                ZStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(Color(hex: "E9E9E9"))
                                }
                                .frame(width: 60, height: 60)
                                .glassEffect(.regular.interactive(), in: Circle())
                            }
                        }
                    }
                    .animation(.bouncy, value: dragOffset)
                    .animation(.bouncy, value: isActive)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(height: 76)
            .padding(.horizontal, 16)
            .onAppear {
                guard !isInitialOffsetSet else { return }
                let index = indexForTab(selectedTab)
                let tabCount = items.count
                let screenWidth = UIScreen.main.bounds.width
                let searchReservedSpace: CGFloat = showSearch ? 72 : 0
                let availableWidth = screenWidth - 32 - searchReservedSpace
                let calculatedItemWidth = availableWidth / CGFloat(tabCount)
                let tabItemWidth = needsScrollingFor(width: screenWidth)
                    ? max(calculatedItemWidth, minItemWidth)
                    : max(min(calculatedItemWidth, maxItemWidth), minItemWidth)
                dragOffset = CGFloat(index) * tabItemWidth
                isInitialOffsetSet = true
            }
            .animation(.smooth, value: selectedTab)
        }
        
        private func needsScrollingFor(width: CGFloat) -> Bool {
            let tabCount = items.count
            let searchReservedSpace: CGFloat = showSearch ? 72 : 0
            let availableWidth = width - 32 - searchReservedSpace
            let calculatedItemWidth = availableWidth / CGFloat(tabCount)
            return calculatedItemWidth < minItemWidth
        }
        
        @ViewBuilder
        private func panelInnerContent(
            tabItemWidth: CGFloat,
            tabItemHeight: CGFloat,
            maxDrag: CGFloat,
            allowDrag: Bool
        ) -> some View {
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \\\\.offset) { index, item in
                        TabItemView(
                            icon: item.icon,
                            title: item.title,
                            itemWidth: tabItemWidth,
                            indicatorHeight: tabItemHeight,
                            foregroundColor: item.color
                        )
                        .contentShape(.capsule)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    selectedTab = item.tab
                                    dragOffset = CGFloat(index) * tabItemWidth
                                }
                        )
                        .if(allowDrag) { view in
                            view.simultaneousGesture(
                                DragGesture(minimumDistance: 0)
                                    .updating($isActive) { _, out, _ in
                                        out = true
                                    }
                                    .onChanged { value in
                                        let xOffset = value.translation.width
                                        if let lastDragOffset {
                                            let newDragOffset = xOffset + lastDragOffset
                                            dragOffset = max(min(newDragOffset, maxDrag), 0)
                                        } else {
                                            lastDragOffset = dragOffset
                                        }
                                    }
                                    .onEnded { _ in
                                        lastDragOffset = nil
                                        let landingIndex = Int((dragOffset / tabItemWidth).rounded())
                                        if items.indices.contains(landingIndex) {
                                            dragOffset = CGFloat(landingIndex) * tabItemWidth
                                            selectedTab = items[landingIndex].tab
                                        }
                                    }
                            )
                        }
                    }
                }
                
                HStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \\\\.offset) { index, item in
                        TabItemView(
                            icon: item.icon,
                            title: item.title,
                            itemWidth: tabItemWidth,
                            indicatorHeight: tabItemHeight,
                            foregroundColor: item.activeColor
                        )
                    }
                }
                .mask(alignment: .leading) {
                    TabBarLensWithMask(
                        width: tabItemWidth,
                        height: tabItemHeight,
                        isLifted: isActive
                    )
                    .frame(width: tabItemWidth, height: tabItemHeight)
                    .scaleEffect(isActive ? 1.3 : 1)
                    .offset(x: dragOffset)
                }
                
                VStack {
                    Spacer(minLength: 0)
                    TabBarLensWithMask(
                        width: tabItemWidth,
                        height: tabItemHeight,
                        isLifted: isActive
                    )
                    .frame(width: tabItemWidth, height: tabItemHeight)
                    .scaleEffect(isActive ? 1.3 : 1)
                    .offset(x: dragOffset + panelPadding)
                    Spacer(minLength: 0)
                }
                .allowsHitTesting(false)
            }
            .padding(panelPadding)
        }
    }

    // MARK: - Conditional Modifier

    extension View {
        @ViewBuilder
        func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
            if condition {
                transform(self)
            } else {
                self
            }
        }
    }

    // MARK: - TabBarBuilder

    @resultBuilder
    struct TabBarBuilder {
        static func buildBlock<Screen: View>(_ components: TabItem<Screen>...) -> [TabItem<Screen>] {
            return components
        }
    }
    """
}
