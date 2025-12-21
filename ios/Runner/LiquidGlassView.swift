// Copyright Luka Löhr 2025
// iOS Liquid Glass View Implementation using Apple's native glass effect API

import SwiftUI
import UIKit

/// SwiftUI representable view that wraps Apple's native liquid glass effect
@available(iOS 18.0, *)
struct LiquidGlassRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        // Create a hosting controller with SwiftUI view using Apple's glass effect
        let hostingController = UIHostingController(
            rootView: GlassBackgroundView()
        )
        
        // Get the view and configure it
        guard let view = hostingController.view else {
            return UIView()
        }
        
        view.backgroundColor = .clear
        view.isOpaque = false
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed for static glass effect
    }
}

/// SwiftUI view that applies the liquid glass effect
@available(iOS 18.0, *)
struct GlassBackgroundView: View {
    var body: some View {
        ZStack {
            // Clear base color
            Color.clear
                .ignoresSafeArea()
        }
        // Apply Apple's native liquid glass effect
        .glassEffect()
    }
}

/// Fallback view for iOS versions below 18.0
struct LiquidGlassFallbackView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        return blurView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}

/// Factory method that creates the appropriate view based on iOS version
func createLiquidGlassView() -> UIView {
    if #available(iOS 18.0, *) {
        // Use native liquid glass on iOS 18+
        let representable = LiquidGlassRepresentable()
        let hostingController = UIHostingController(rootView: representable)
        guard let view = hostingController.view else {
            return createFallbackGlassView()
        }
        view.backgroundColor = .clear
        view.isOpaque = false
        return view
    } else {
        // Use blur fallback on older iOS versions
        return createFallbackGlassView()
    }
}

/// Creates a fallback glass view using UIVisualEffectView
func createFallbackGlassView() -> UIView {
    let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
    let blurView = UIVisualEffectView(effect: blurEffect)
    blurView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
    return blurView
}

