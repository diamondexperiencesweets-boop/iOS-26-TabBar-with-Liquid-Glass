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

// MARK: - Panel Alignment

enum GlassTabBarAlignment {
    case center
    case panelLeftSearchRight
    case searchLeftPanelRight
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
    private let alignment: GlassTabBarAlignment
    private let searchAction: ((String) -> Void)?
    
    @Binding private var selectedTab: AppTab
    @Binding private var searchText: String
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat?
    @State private var isSearchActive: Bool = false
    
    private let panelPadding: CGFloat = 2
    private let minItemWidth: CGFloat = 60
    private let maxItemWidth: CGFloat = 90
    private let lensInset: CGFloat = 2
    private let scrollLensExtraWidth: CGFloat = 10
    
    @State private var cachedNeedsScrolling: Bool = false
    @State private var cachedPanelWidth: CGFloat = 0
    @State private var cachedTabItemWidth: CGFloat = 0
    @State private var cachedLensWidth: CGFloat = 0
    @State private var cachedLensInsetScroll: CGFloat = 0
    @State private var cachedTotalContentWidth: CGFloat = 0
    @State private var cachedMaxDrag: CGFloat = 0
    
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
         searchText: Binding<String> = .constant(""),
         showSearch: Bool = true,
         alignment: GlassTabBarAlignment = .center,
         searchAction: ((String) -> Void)? = nil,
         @TabBarBuilder items: () -> [TabItem<Screen>]) {
        self.type = type
        self._selectedTab = selectedTab
        self._searchText = searchText
        self.showSearch = showSearch
        self.alignment = alignment
        self.searchAction = searchAction
        self.items = items()
    }
    
    private func indexForTab(_ tab: AppTab) -> Int {
        items.firstIndex(where: { $0.tab == tab }) ?? 0
    }
    
    private func recalculateCache(totalWidth: CGFloat) {
        let tabCount = items.count
        let searchHeight: CGFloat = isSearchActive ? 48 : 60
        let searchReservedSpace: CGFloat = showSearch ? (12 + searchHeight) : 0
        let availableWidth = totalWidth - searchReservedSpace
        
        let calculatedItemWidth = availableWidth / CGFloat(tabCount)
        let needsScrolling = !allItemsFit
        
        let panelWidth: CGFloat = isSearchActive
            ? availableWidth
            : (needsScrolling
                ? availableWidth
                : max(min(calculatedItemWidth, maxItemWidth), minItemWidth) * CGFloat(tabCount))
        
        let tabItemWidth: CGFloat = needsScrolling
            ? max(calculatedItemWidth, minItemWidth)
            : max(min(calculatedItemWidth, maxItemWidth), minItemWidth)
        
        let lensWidth: CGFloat = needsScrolling
            ? (tabItemWidth - lensInset * 2 + scrollLensExtraWidth)
            : (tabItemWidth - lensInset * 2)
        
        let lensInsetScroll: CGFloat = needsScrolling
            ? lensInset - scrollLensExtraWidth / 2
            : lensInset
        
        let totalContentWidth = tabItemWidth * CGFloat(tabCount)
        let maxDrag = totalContentWidth - tabItemWidth
        
        cachedNeedsScrolling = needsScrolling
        cachedPanelWidth = panelWidth
        cachedTabItemWidth = tabItemWidth
        cachedLensWidth = lensWidth
        cachedLensInsetScroll = lensInsetScroll
        cachedTotalContentWidth = totalContentWidth
        cachedMaxDrag = maxDrag
    }
    
    private var currentHeight: CGFloat {
        isSearchActive ? 48 : 60
    }
    
    private var currentTabItemHeight: CGFloat {
        isSearchActive ? 47 : 59
    }
    
    private var searchButton: some View {
        Button {
            if isSearchActive && !searchText.isEmpty {
                searchAction?(searchText)
                return
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isSearchActive.toggle()
                if !isSearchActive {
                    searchText = ""
                }
            }
            let screenWidth = UIScreen.main.bounds.width
            recalculateCache(totalWidth: screenWidth - 32)
        } label: {
            ZStack {
                Image(systemName: isSearchActive ? (searchText.isEmpty ? "xmark" : "magnifyingglass") : "magnifyingglass")
                    .font(.system(size: isSearchActive ? 20 : 24, weight: .medium))
                    .foregroundColor(Color(hex: "E9E9E9"))
            }
            .frame(width: currentHeight, height: currentHeight)
            .glassEffect(.regular.interactive(), in: Circle())
            .offset(y: isSearchActive ? -5 : 0)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let panelHeight = currentTabItemHeight + panelPadding * 2
            
            if isInitialOffsetSet {
                Group {
                    switch alignment {
                    case .center:
                        HStack(spacing: 12) {
                            ZStack {
                                panelView(
                                    needsScrolling: cachedNeedsScrolling,
                                    tabItemWidth: cachedTabItemWidth,
                                    tabItemHeight: currentTabItemHeight,
                                    totalContentWidth: cachedTotalContentWidth,
                                    maxDrag: cachedMaxDrag,
                                    panelWidth: cachedPanelWidth,
                                    panelHeight: panelHeight,
                                    lensWidth: cachedLensWidth,
                                    lensInsetScroll: cachedLensInsetScroll
                                )
                                .opacity(isSearchActive ? 0 : 1)
                                .scaleEffect(isSearchActive ? 0.95 : 1)
                                .blur(radius: isSearchActive ? 8 : 0)
                                
                                searchField(panelHeight: panelHeight)
                                    .opacity(isSearchActive ? 1 : 0)
                                    .scaleEffect(isSearchActive ? 1 : 0.95)
                                    .blur(radius: isSearchActive ? 0 : 8)
                            }
                            .offset(y: isSearchActive ? -5 : 0)
                            
                            if showSearch {
                                searchButton
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                    case .panelLeftSearchRight:
                        HStack(spacing: 0) {
                            ZStack {
                                panelView(
                                    needsScrolling: cachedNeedsScrolling,
                                    tabItemWidth: cachedTabItemWidth,
                                    tabItemHeight: currentTabItemHeight,
                                    totalContentWidth: cachedTotalContentWidth,
                                    maxDrag: cachedMaxDrag,
                                    panelWidth: cachedPanelWidth,
                                    panelHeight: panelHeight,
                                    lensWidth: cachedLensWidth,
                                    lensInsetScroll: cachedLensInsetScroll
                                )
                                .opacity(isSearchActive ? 0 : 1)
                                .scaleEffect(isSearchActive ? 0.95 : 1)
                                .blur(radius: isSearchActive ? 8 : 0)
                                
                                searchField(panelHeight: panelHeight)
                                    .opacity(isSearchActive ? 1 : 0)
                                    .scaleEffect(isSearchActive ? 1 : 0.95)
                                    .blur(radius: isSearchActive ? 0 : 8)
                            }
                            .offset(y: isSearchActive ? -5 : 0)
                            
                            Spacer()
                            
                            if showSearch {
                                searchButton
                            }
                        }
                        
                    case .searchLeftPanelRight:
                        HStack(spacing: 0) {
                            if showSearch {
                                searchButton
                            }
                            
                            Spacer()
                            
                            ZStack {
                                panelView(
                                    needsScrolling: cachedNeedsScrolling,
                                    tabItemWidth: cachedTabItemWidth,
                                    tabItemHeight: currentTabItemHeight,
                                    totalContentWidth: cachedTotalContentWidth,
                                    maxDrag: cachedMaxDrag,
                                    panelWidth: cachedPanelWidth,
                                    panelHeight: panelHeight,
                                    lensWidth: cachedLensWidth,
                                    lensInsetScroll: cachedLensInsetScroll
                                )
                                .opacity(isSearchActive ? 0 : 1)
                                .scaleEffect(isSearchActive ? 0.95 : 1)
                                .blur(radius: isSearchActive ? 8 : 0)
                                
                                searchField(panelHeight: panelHeight)
                                    .opacity(isSearchActive ? 1 : 0)
                                    .scaleEffect(isSearchActive ? 1 : 0.95)
                                    .blur(radius: isSearchActive ? 0 : 8)
                            }
                            .offset(y: isSearchActive ? -5 : 0)
                        }
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: dragOffset)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isActive)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSearchActive)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 76)
        .padding(.horizontal, 16)
        .onAppear {
            guard !isInitialOffsetSet else { return }
            let screenWidth = UIScreen.main.bounds.width
            recalculateCache(totalWidth: screenWidth - 32)
            let index = indexForTab(selectedTab)
            dragOffset = CGFloat(index) * cachedTabItemWidth
            isInitialOffsetSet = true
        }
        .animation(.smooth, value: selectedTab)
    }
    
    // MARK: - Search Field
    
    private func searchField(panelHeight: CGFloat) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: "E9E9E9").opacity(0.6))
            
            TextField("Поиск", text: $searchText)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .tint(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: panelHeight)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
    }
    
    // MARK: - Panel View
    
    @ViewBuilder
    private func panelView(needsScrolling: Bool, tabItemWidth: CGFloat, tabItemHeight: CGFloat, totalContentWidth: CGFloat, maxDrag: CGFloat, panelWidth: CGFloat, panelHeight: CGFloat, lensWidth: CGFloat, lensInsetScroll: CGFloat) -> some View {
        if needsScrolling {
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
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
                        }
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
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
                            width: lensWidth,
                            height: tabItemHeight,
                            isLifted: isActive
                        )
                        .frame(width: lensWidth, height: tabItemHeight)
                        .scaleEffect(isActive ? 1.3 : 1)
                        .offset(x: dragOffset + lensInsetScroll)
                    }
                    
                    TabBarLensWithMask(
                        width: lensWidth,
                        height: tabItemHeight,
                        isLifted: isActive
                    )
                    .frame(width: lensWidth, height: tabItemHeight)
                    .scaleEffect(isActive ? 1.3 : 1)
                    .offset(x: dragOffset + lensInsetScroll)
                    .allowsHitTesting(false)
                }
                .padding(panelPadding)
                .frame(width: totalContentWidth, height: panelHeight)
            }
            .frame(width: panelWidth, height: panelHeight)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
        } else {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            TabItemView(
                                icon: item.icon,
                                title: item.title,
                                itemWidth: tabItemWidth,
                                indicatorHeight: tabItemHeight,
                                foregroundColor: item.color
                            )
                            .contentShape(.capsule)
                            .simultaneousGesture(
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
                            .simultaneousGesture(
                                TapGesture()
                                    .onEnded { _ in
                                        selectedTab = item.tab
                                        dragOffset = CGFloat(index) * tabItemWidth
                                    }
                            )
                        }
                    }
                    
                    HStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
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
                            width: lensWidth,
                            height: tabItemHeight,
                            isLifted: isActive
                        )
                        .frame(width: lensWidth, height: tabItemHeight)
                        .scaleEffect(isActive ? 1.3 : 1)
                        .offset(x: dragOffset + lensInset)
                    }
                }
                .padding(panelPadding)
                .frame(width: panelWidth, height: panelHeight)
                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 32))
                
                TabBarLensWithMask(
                    width: lensWidth,
                    height: tabItemHeight,
                    isLifted: isActive
                )
                .frame(width: lensWidth, height: tabItemHeight)
                .scaleEffect(isActive ? 1.3 : 1)
                .offset(x: dragOffset + lensInset, y: panelPadding)
                .allowsHitTesting(false)
            }
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

#Preview {
    ZStack {
        Color.blue.ignoresSafeArea()
        VStack {
            Spacer()
            GlassTabBar(selectedTab: .constant(.Chats), searchText: .constant(""), showSearch: true, alignment: .panelLeftSearchRight, searchAction: { query in
                print("Поиск: \(query)")
            }) {
                TabItem(icon: "phone.badge.waveform.fill", color: .white, activeColor: .yellow, title: "Звонки", tab: .Calls) {
                    Text("Звонки")
                }
                TabItem(icon: "message.fill", color: .white, activeColor: .orange, title: "Чаты", tab: .Chats) {
                    Text("Чаты")
                }
                TabItem(icon: "gear", color: .white, activeColor: .mint, title: "Настройки", tab: .Settings) {
                    Text("Настройки")
                }
            }
        }
    }
}
