//
//  LiquidLensRepresentable.swift
//  NavigationTabBar1
//
//  Created by Павел Семин on 29.04.2026.
//

import SwiftUI

struct CenterLensRepresentable: UIViewRepresentable {
    @Binding var lensState: LensState
    @Binding var lensOffsetX: CGFloat
    
    func makeUIView(context: Context) -> LiquidLensView {
        let lensView = LiquidLensView(kind: .noContainer)
        lensView.backgroundColor = .clear
        return lensView
    }
    
    func updateUIView(_ uiView: LiquidLensView, context: Context) {
        let isLifted = (lensState == .lifted)
        let size = CGSize(width: 80, height: 80)
        
        let selectionSize = CGSize(
            width: size.width * 0.9,
            height: size.height * 0.85
        )
        let selectionOrigin = CGPoint(
            x: (size.width - selectionSize.width) / 2 + lensOffsetX,
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
