//
//  ContentView.swift
//  NavigationTabBar1
//
//  Created by Павел Семин on 28.04.2026.
//

import SwiftUI

// MARK: - AppTab

enum AppTab {
    case Calls, Chats, Settings
}

// MARK: - Lens State

enum LensState {
    case resting
    case lifted
}

// MARK: - Screens

struct CallsScreen: View {
    var body: some View {
        ZStack {
            Image("Image_1")
                .resizable()
                .ignoresSafeArea()
            
            Text("Звонки")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

struct ChatsScreen: View {
    var body: some View {
        ZStack {
            Image("Image_2")
                .resizable()
                .ignoresSafeArea()
            
            Text("Чаты")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

struct SettingsScreen: View {
    var body: some View {
        ZStack {
            Image("Image_3")
                .resizable()
                .ignoresSafeArea()
            
            Text("Настройки")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Code Sheet View

struct CodeSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    let code: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color.black.opacity(0.9))
            .navigationTitle("Код панели навигации")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Image(systemName: "document.on.clipboard")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab = .Chats
    @State private var lensState: LensState = .resting
    @State private var lensOffsetX: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var searchEnabled: Bool = true
    @State private var showCodeSheet: Bool = false
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                currentScreen
                
                VStack {
                    Spacer()
                    
                    GlassTabBar(selectedTab: $selectedTab, searchText: $searchText, showSearch: searchEnabled, alignment: .panelLeftSearchRight, searchAction: { query in
                        // Поиск выполнен — текст в searchText доступен
                        print("Поиск: \(query)")
                    }) {
                        TabItem(icon: "phone.badge.waveform.fill", color: .white, activeColor: Color(hex: "0673E1"), title: "Звонки", tab: .Calls) {
                            EmptyView()
                        }
                        TabItem(icon: "message.fill", color: .white, activeColor: Color(hex: "0673E1"), title: "Чаты", tab: .Chats) {
                            EmptyView()
                        }
                        TabItem(icon: "gear", color: .white, activeColor: Color(hex: "0673E1"), title: "Настройки", tab: .Settings) {
                            EmptyView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCodeSheet = true
                    } label: {
                        Image(systemName: "chart.line.text.clipboard")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            searchEnabled.toggle()
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundColor(searchEnabled ? .white : .gray)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .sheet(isPresented: $showCodeSheet) {
                CodeSheetView(code: NavigationBarCode.code)
            }
        }
    }
    
    // MARK: - Current Screen
    
    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .Calls:
            CallsScreen()
        case .Chats:
            ChatsScreen()
        case .Settings:
            SettingsScreen()
        }
    }
}

#Preview {
    ContentView()
}
