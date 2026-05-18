//
//  LiquidLensView.swift
//  NavigationTabBar1
//
//  Created by Павел Семин on 29.04.2026.
//

import UIKit

// MARK: - RestingBackgroundView

private final class RestingBackgroundView: UIVisualEffectView {
    var isDark: Bool?

    static func colorMatrix(isDark: Bool) -> [Float32] {
        if isDark {
            return [1.082, -0.113, -0.011, 0.0, 0.135,
                    -0.034, 1.003, -0.011, 0.0, 0.135,
                    -0.034, -0.113, 1.105, 0.0, 0.135,
                    0.0, 0.0, 0.0, 1.0, 0.0]
        } else {
            return [1.185, -0.05, -0.005, 0.0, -0.2,
                    -0.015, 1.15, -0.005, 0.0, -0.2,
                    -0.015, -0.05, 1.195, 0.0, -0.2,
                    0.0, 0.0, 0.0, 1.0, 0.0]
        }
    }

    override init(effect: UIVisualEffect?) {
        super.init(effect: UIBlurEffect(style: .light))
        
        for subview in self.subviews {
            if String(describing: subview).contains("VisualEffectSubview") {
                subview.isHidden = true
            }
        }
        
        self.clipsToBounds = true
        self.backgroundColor = UIColor.white.withAlphaComponent(0.2)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(isDark: Bool) {
        if self.isDark == isDark {
            return
        }
        self.isDark = isDark
        
        guard let sublayer = self.layer.sublayers?.first,
              sublayer.filters != nil else {
            return
        }
        
        sublayer.backgroundColor = nil
        sublayer.isOpaque = false
        
        guard let classValue = NSClassFromString("CAFilter") as AnyObject as? NSObjectProtocol else {
            return
        }
        
        let makeSelector = NSSelectorFromString("filterWithName:")
        guard let filter = classValue.perform(makeSelector, with: "colorMatrix")?.takeUnretainedValue() as? NSObject else {
            return
        }
        
        var matrix: [Float32] = RestingBackgroundView.colorMatrix(isDark: isDark)
        filter.setValue(
            NSValue(bytes: &matrix, objCType: "{CAColorMatrix=ffffffffffffffffffff}"),
            forKey: "inputColorMatrix"
        )
        sublayer.filters = [filter]
        sublayer.setValue(1.0, forKey: "scale")
    }
}

// MARK: - ComponentTransition

public struct ComponentTransition {
    public let animation: Animation
    
    public struct Animation {
        public let isImmediate: Bool
        
        public static let immediate = Animation(isImmediate: true)
        public static func spring(duration: Double) -> Animation {
            return Animation(isImmediate: false)
        }
    }
    
    public static let immediate = ComponentTransition(animation: .immediate)
    
    public init(animation: Animation) {
        self.animation = animation
    }
    
    public func userData<T>(_ type: T.Type) -> T? {
        return nil
    }
    
    public func setFrame(view: UIView, frame: CGRect, completion: ((Bool) -> Void)? = nil) {
        if animation.isImmediate {
            view.frame = frame
            completion?(true)
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
                view.frame = frame
            } completion: { completed in
                completion?(completed)
            }
        }
    }
    
    public func setPosition(view: UIView, position: CGPoint, completion: ((Bool) -> Void)? = nil) {
        if animation.isImmediate {
            view.center = position
            completion?(true)
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction]) {
                view.center = position
            } completion: { completed in
                completion?(completed)
            }
        }
    }
    
    public func setCornerRadius(layer: CALayer, cornerRadius: CGFloat) {
        if animation.isImmediate {
            layer.cornerRadius = cornerRadius
        } else {
            let anim = CABasicAnimation(keyPath: "cornerRadius")
            anim.fromValue = layer.cornerRadius
            anim.toValue = cornerRadius
            anim.duration = 0.35
            anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            layer.add(anim, forKey: "cornerRadius")
            layer.cornerRadius = cornerRadius
        }
    }
    
    public func setAlpha(view: UIView, alpha: CGFloat) {
        if animation.isImmediate {
            view.alpha = alpha
        } else {
            UIView.animate(withDuration: 0.35) {
                view.alpha = alpha
            }
        }
    }
    
    public func animateView(_ animations: @escaping () -> Void) {
        if animation.isImmediate {
            animations()
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction], animations: animations)
        }
    }
    
    public func animatePosition(layer: CALayer, from: CGPoint, to: CGPoint, additive: Bool) {
        guard !animation.isImmediate else { return }
    }
}

// MARK: - SharedDisplayLinkDriver

public final class SharedDisplayLinkDriver {
    public static let shared = SharedDisplayLinkDriver()
    
    public final class Link {
        private var displayLink: CADisplayLink?
        private var callback: (Double) -> Void
        
        init(displayLink: CADisplayLink? = nil, callback: @escaping (Double) -> Void) {
            self.displayLink = displayLink
            self.callback = callback
        }
        
        public func invalidate() {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    public enum FramesPerSecond {
        case max
    }
    
    public func add(framesPerSecond: FramesPerSecond, _ callback: @escaping (Double) -> Void) -> Link {
        let displayLink = CADisplayLink(target: self, selector: #selector(displayLinkTick(_:)))
        displayLink.add(to: .main, forMode: .common)
        return Link(displayLink: displayLink, callback: callback)
    }
    
    @objc private func displayLinkTick(_ displayLink: CADisplayLink) {
    }
}

// MARK: - GlassBackgroundView

public final class GlassBackgroundView: UIView {
    
    public enum TintColorKind {
        case panel
    }
    
    public struct TintColor {
        public let kind: TintColorKind
        
        public init(kind: TintColorKind) {
            self.kind = kind
        }
    }
    
    public let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
    
    public func update(
        size: CGSize,
        cornerRadius: CGFloat,
        isDark: Bool,
        tintColor: TintColor,
        isInteractive: Bool,
        transition: ComponentTransition
    ) {
        self.layer.cornerRadius = cornerRadius
        self.clipsToBounds = true
    }
}

// MARK: - GlassBackgroundContainerView

public final class GlassBackgroundContainerView: UIView {
    public let contentView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = self.bounds
    }
    
    public func update(size: CGSize, isDark: Bool, transition: ComponentTransition) {
    }
}

// MARK: - LiquidLensView

public final class LiquidLensView: UIView {
    
    // MARK: - TransitionInfo
    
    public final class TransitionInfo {
        public let disableAnimationWorkarounds: Bool
        
        public init(disableAnimationWorkarounds: Bool) {
            self.disableAnimationWorkarounds = disableAnimationWorkarounds
        }
    }
    
    // MARK: - Kind
    
    public enum Kind {
        case externalContainer
        case builtinContainer
        case noContainer
    }
    
    // MARK: - Params
    
    private struct Params: Equatable {
        var size: CGSize
        var cornerRadius: CGFloat?
        var selectionOrigin: CGPoint
        var selectionSize: CGSize
        var inset: CGFloat
        var liftedInset: CGFloat
        var isDark: Bool
        var isLifted: Bool
        var isCollapsed: Bool

        init(
            size: CGSize,
            cornerRadius: CGFloat?,
            selectionOrigin: CGPoint,
            selectionSize: CGSize,
            inset: CGFloat,
            liftedInset: CGFloat,
            isDark: Bool,
            isLifted: Bool,
            isCollapsed: Bool
        ) {
            self.size = size
            self.cornerRadius = cornerRadius
            self.selectionOrigin = selectionOrigin
            self.selectionSize = selectionSize
            self.inset = inset
            self.liftedInset = liftedInset
            self.isLifted = isLifted
            self.isDark = isDark
            self.isCollapsed = isCollapsed
        }
    }

    private struct LensParams: Equatable {
        var baseFrame: CGRect
        var inset: CGFloat
        var liftedInset: CGFloat
        var isLifted: Bool

        init(baseFrame: CGRect, inset: CGFloat, liftedInset: CGFloat, isLifted: Bool) {
            self.baseFrame = baseFrame
            self.inset = inset
            self.liftedInset = liftedInset
            self.isLifted = isLifted
        }
    }
    
    // MARK: - Private Properties
    
    private let containerView: UIView
    private let backgroundContainer: GlassBackgroundContainerView?
    private let genericBackgroundContainer: UIView?
    private let backgroundView: GlassBackgroundView?
    private var lensView: UIView?
    private let liftedContainerView: UIView
    public let contentView: UIView
    private let restingBackgroundView: RestingBackgroundView

    public var selectedContentView: UIView {
        return self.liftedContainerView
    }

    private var params: Params?
    private var appliedLensParams: LensParams?
    private var isApplyingLensParams: Bool = false
    private var pendingLensParams: LensParams?

    private var liftedDisplayLink: SharedDisplayLinkDriver.Link?

    public var selectionOrigin: CGPoint? {
        return self.params?.selectionOrigin
    }

    public var selectionSize: CGSize? {
        return self.params?.selectionSize
    }
    
    public private(set) var isAnimating: Bool = false {
        didSet {
            if self.isAnimating != oldValue {
                self.onUpdatedIsAnimating?(self.isAnimating)
            }
        }
    }
    public var onUpdatedIsAnimating: ((Bool) -> Void)?
    public var isLiftedAnimationCompleted: (() -> Void)?

    // MARK: - Initialization
    
    public init(kind: Kind) {
        self.containerView = UIView()
        
        switch kind {
        case .builtinContainer:
            self.backgroundContainer = GlassBackgroundContainerView()
            self.genericBackgroundContainer = nil
        case .externalContainer, .noContainer:
            self.backgroundContainer = nil
            self.genericBackgroundContainer = UIView()
        }
        
        if case .noContainer = kind {
            self.backgroundView = nil
        } else {
            self.backgroundView = GlassBackgroundView()
        }
        
        self.contentView = UIView()
        self.liftedContainerView = UIView()

        self.restingBackgroundView = RestingBackgroundView(effect: nil)

        super.init(frame: CGRect())
        
        setupViewHierarchy(kind: kind)
        setupLensView(kind: kind)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Methods
    
    private func setupViewHierarchy(kind: Kind) {
        if let backgroundContainer = self.backgroundContainer {
            self.addSubview(backgroundContainer)
            if let backgroundView = self.backgroundView {
                backgroundContainer.contentView.addSubview(backgroundView)
                backgroundView.contentView.addSubview(self.containerView)
            }
        } else if let genericBackgroundContainer = self.genericBackgroundContainer {
            self.addSubview(genericBackgroundContainer)
            if let backgroundView = self.backgroundView {
                genericBackgroundContainer.addSubview(backgroundView)
                backgroundView.contentView.addSubview(self.containerView)
            } else {
                genericBackgroundContainer.addSubview(self.containerView)
            }
        }
        self.containerView.isUserInteractionEnabled = false
    }
    
    private func setupLensView(kind: Kind) {
        guard let viewClass = NSClassFromString("_UILiquidLensView") as AnyObject as? NSObjectProtocol else {
            fatalError("_UILiquidLensView доступен только на iOS 26+")
        }
        
        let allocSelector = NSSelectorFromString("alloc")
        let initSelector = NSSelectorFromString("initWithRestingBackground:")
        
        guard let objcAlloc = viewClass.perform(allocSelector)?.takeUnretainedValue() else {
            fatalError("Не удалось создать _UILiquidLensView")
        }
        
        guard let instance = objcAlloc.perform(initSelector, with: UIView())?.takeUnretainedValue() else {
            fatalError("Не удалось инициализировать _UILiquidLensView")
        }
        
        self.lensView = instance as? UIView
        
        guard let lensView = self.lensView else {
            fatalError("_UILiquidLensView не UIView")
        }
        
        configureNativeLensView(lensView, kind: kind)
    }
    
    private func configureNativeLensView(_ lensView: UIView, kind: Kind) {
        if let backgroundContainer = self.backgroundContainer {
            backgroundContainer.layer.zPosition = 1
        } else if let genericBackgroundContainer = self.genericBackgroundContainer {
            genericBackgroundContainer.layer.zPosition = 1
        }
        lensView.layer.zPosition = 10.0
        
        self.liftedContainerView.addSubview(self.restingBackgroundView)
        
        self.containerView.addSubview(self.liftedContainerView)
        self.containerView.addSubview(lensView)
        self.containerView.addSubview(self.contentView)
        
        if let backgroundContainer = self.backgroundContainer {
            lensView.perform(
                NSSelectorFromString("setLiftedContainerView:"),
                with: backgroundContainer.contentView
            )
        } else if let genericBackgroundContainer = self.genericBackgroundContainer {
            lensView.perform(
                NSSelectorFromString("setLiftedContainerView:"),
                with: genericBackgroundContainer
            )
        }
        
        lensView.perform(
            NSSelectorFromString("setLiftedContentView:"),
            with: self.liftedContainerView
        )
        lensView.perform(
            NSSelectorFromString("setOverridePunchoutView:"),
            with: self.contentView
        )
        
        performSelector(on: lensView, selector: "setLiftedContentMode:", intValue: 0)
        performSelector(on: lensView, selector: "setStyle:", intValue: 1)
        performSelector(on: lensView, selector: "setWarpsContentBelow:", boolValue: true)
        
        lensView.setValue(
            UIColor.white.withAlphaComponent(0.1),
            forKey: "restingBackgroundColor"
        )
    }
    
    private func performSelector(on object: NSObject, selector: String, intValue: Int32) {
        let sel = NSSelectorFromString(selector)
        guard object.responds(to: sel) else { return }
        
        typealias ObjCMethod = @convention(c) (AnyObject, Selector, Int32) -> Void
        let method = object.method(for: sel)
        let function = unsafeBitCast(method, to: ObjCMethod.self)
        function(object, sel, intValue)
    }
    
    private func performSelector(on object: NSObject, selector: String, boolValue: Bool) {
        let sel = NSSelectorFromString(selector)
        guard object.responds(to: sel) else { return }
        
        typealias ObjCMethod = @convention(c) (AnyObject, Selector, Bool) -> Void
        let method = object.method(for: sel)
        let function = unsafeBitCast(method, to: ObjCMethod.self)
        function(object, sel, boolValue)
    }
    
    // MARK: - Public Methods
    
    public func setLiftedContainer(view: UIView) {
        guard let lensView = self.lensView else {
            return
        }
        lensView.perform(
            NSSelectorFromString("setLiftedContainerView:"),
            with: view
        )
    }

    public func update(
        size: CGSize,
        cornerRadius: CGFloat? = nil,
        selectionOrigin: CGPoint,
        selectionSize: CGSize,
        inset: CGFloat,
        liftedInset: CGFloat = 4.0,
        isDark: Bool,
        isLifted: Bool,
        isCollapsed: Bool = false,
        transition: ComponentTransition = .immediate
    ) {
        let params = Params(
            size: size,
            cornerRadius: cornerRadius,
            selectionOrigin: selectionOrigin,
            selectionSize: selectionSize,
            inset: inset,
            liftedInset: liftedInset,
            isDark: isDark,
            isLifted: isLifted,
            isCollapsed: isCollapsed
        )
        if self.params == params {
            return
        }
        self.update(params: params, transition: transition)
    }

    private func update(transition: ComponentTransition) {
        guard let params = self.params else {
            return
        }
        self.update(params: params, transition: transition)
    }
    
    // MARK: - Lens Update
    
    private func updateLens(params: LensParams, transition: ComponentTransition) {
        guard let lensView = self.lensView else {
            return
        }

        if self.isApplyingLensParams {
            self.pendingLensParams = params
            return
        }
        self.isApplyingLensParams = true
        let previousParams = self.appliedLensParams
        self.appliedLensParams = params

        if previousParams?.isLifted != params.isLifted {
            handleLiftedStateChange(params: params, lensView: lensView, transition: transition)
        } else {
            handleLensPositionUpdate(params: params, lensView: lensView, transition: transition)
        }
    }
    
    private func handleLiftedStateChange(
        params: LensParams,
        lensView: UIView,
        transition: ComponentTransition
    ) {
        self.isAnimating = true
        
        let selector = NSSelectorFromString("setLifted:animated:alongsideAnimations:completion:")
        var shouldScheduleUpdate = false
        var didProcessUpdate = false
        self.pendingLensParams = params
        
        guard lensView.responds(to: selector) else {
            self.isApplyingLensParams = false
            return
        }
        
        typealias ObjCMethod = @convention(c) (
            AnyObject, Selector, Bool, Bool,
            @escaping () -> Void, (() -> Void)?
        ) -> Void
        
        let method = lensView.method(for: selector)
        let function = unsafeBitCast(method, to: ObjCMethod.self)
        
        function(
            lensView, selector,
            params.isLifted,
            !transition.animation.isImmediate,
            { [weak self] in
                guard let self else { return }
                let liftedInset: CGFloat = params.isLifted
                    ? params.liftedInset
                    : (-params.inset)
                lensView.bounds = CGRect(
                    origin: CGPoint(),
                    size: CGSize(
                        width: params.baseFrame.width + liftedInset * 2.0,
                        height: params.baseFrame.height + liftedInset * 2.0
                    )
                )
                didProcessUpdate = true
                if shouldScheduleUpdate {
                    DispatchQueue.main.async { [weak self] in
                        guard let self,
                              let pendingLensParams = self.pendingLensParams else {
                            return
                        }
                        self.isApplyingLensParams = false
                        self.pendingLensParams = nil
                        self.updateLens(
                            params: pendingLensParams,
                            transition: transition
                        )
                    }
                }
            },
            { [weak self] in
                guard let self else { return }
                if !self.isApplyingLensParams {
                    self.isAnimating = false
                }
                self.isLiftedAnimationCompleted?()
            }
        )
        
        if didProcessUpdate {
            transition.animateView {
                lensView.center = CGPoint(
                    x: params.baseFrame.midX,
                    y: params.baseFrame.midY
                )
            }
            self.pendingLensParams = nil
            self.isApplyingLensParams = false
        } else {
            shouldScheduleUpdate = true
        }
    }
    
    private func handleLensPositionUpdate(
        params: LensParams,
        lensView: UIView,
        transition: ComponentTransition
    ) {
        let liftedInset: CGFloat = params.isLifted
            ? params.liftedInset
            : (-params.inset)
        let lensBounds = CGRect(
            origin: CGPoint(),
            size: CGSize(
                width: params.baseFrame.width + liftedInset * 2.0,
                height: params.baseFrame.height + liftedInset * 2.0
            )
        )
        let lensCenter = CGPoint(
            x: params.baseFrame.midX,
            y: params.baseFrame.midY
        )
        
        let previousBounds: CGRect = lensView.bounds
        transition.animateView {
            lensView.bounds = lensBounds
        }
        
        if let info = transition.userData(TransitionInfo.self),
           info.disableAnimationWorkarounds {
        } else {
            lensView.layer.removeAllAnimations()
            lensView.bounds = lensBounds
        }
        
        if !transition.animation.isImmediate {
            self.isAnimating = true
        }
        transition.setPosition(view: lensView, position: lensCenter) { [weak self] flag in
            guard let self, flag else { return }
            if !self.isApplyingLensParams {
                self.isAnimating = false
            }
        }
        
        transition.animatePosition(
            layer: lensView.layer,
            from: CGPoint(
                x: (lensBounds.width - previousBounds.width) * 0.5,
                y: 0.0
            ),
            to: CGPoint(),
            additive: true
        )
        
        self.isApplyingLensParams = false
    }

    private func updateLiftedLensPosition() {
        if self.isApplyingLensParams {
            return
        }
        guard let lensView = self.lensView else {
            return
        }
        guard let params = self.appliedLensParams else {
            return
        }
        lensView.center = CGPoint(
            x: params.baseFrame.midX,
            y: params.baseFrame.midY
        )
    }

    private func update(params: Params, transition: ComponentTransition) {
        let isFirstTime = self.params == nil
        let transition: ComponentTransition = isFirstTime ? .immediate : transition

        self.params = params

        transition.setFrame(
            view: self.containerView,
            frame: CGRect(origin: CGPoint(), size: params.size)
        )

        if let backgroundContainer = self.backgroundContainer {
            transition.setFrame(
                view: backgroundContainer,
                frame: CGRect(origin: CGPoint(), size: params.size)
            )
            backgroundContainer.update(
                size: params.size,
                isDark: params.isDark,
                transition: transition
            )
        } else if let genericBackgroundContainer = self.genericBackgroundContainer {
            transition.setFrame(
                view: genericBackgroundContainer,
                frame: CGRect(origin: CGPoint(), size: params.size)
            )
        }
        
        if let backgroundView = self.backgroundView {
            transition.setFrame(
                view: backgroundView,
                frame: CGRect(origin: CGPoint(), size: params.size)
            )
            backgroundView.update(
                size: params.size,
                cornerRadius: params.cornerRadius ?? (params.size.height * 0.5),
                isDark: params.isDark,
                tintColor: GlassBackgroundView.TintColor(kind: .panel),
                isInteractive: true,
                transition: transition
            )
        }
        
        if self.contentView.bounds.size != params.size {
            self.contentView.clipsToBounds = true
            transition.setFrame(
                view: self.contentView,
                frame: CGRect(origin: CGPoint(), size: params.size),
                completion: { [weak self] completed in
                    guard let self, completed else { return }
                    self.contentView.clipsToBounds = false
                }
            )
            transition.setCornerRadius(
                layer: self.contentView.layer,
                cornerRadius: params.cornerRadius ?? (params.size.height * 0.5)
            )

            self.liftedContainerView.clipsToBounds = true
            transition.setFrame(
                view: self.liftedContainerView,
                frame: CGRect(origin: CGPoint(), size: params.size),
                completion: { [weak self] completed in
                    guard let self, completed else { return }
                    self.liftedContainerView.clipsToBounds = false
                }
            )
            transition.setCornerRadius(
                layer: self.liftedContainerView.layer,
                cornerRadius: params.cornerRadius ?? (params.size.height * 0.5)
            )
        }

        let baseLensFrame = CGRect(
            origin: params.selectionOrigin,
            size: params.selectionSize
        )
        self.updateLens(
            params: LensParams(
                baseFrame: baseLensFrame,
                inset: params.inset,
                liftedInset: params.liftedInset,
                isLifted: params.isLifted
            ),
            transition: transition
        )
        
        updateRestingBackground(params: params, transition: transition)
        updateDisplayLink(isLifted: params.isLifted)
    }
    
    private func updateRestingBackground(
        params: Params,
        transition: ComponentTransition
    ) {
        let maxCornerRadius = params.size.height / 2
        let cornerRadius = params.cornerRadius ?? maxCornerRadius
        
        transition.setFrame(
            view: self.restingBackgroundView,
            frame: CGRect(origin: CGPoint(), size: params.size)
        )
        self.restingBackgroundView.layer.cornerRadius = cornerRadius
        self.restingBackgroundView.layer.cornerCurve = .continuous
        self.restingBackgroundView.clipsToBounds = true
        self.restingBackgroundView.update(isDark: params.isDark)
        transition.setAlpha(
            view: self.restingBackgroundView,
            alpha: (params.isLifted || params.isCollapsed) ? 0.0 : 1.0
        )
    }
    
    private func updateDisplayLink(isLifted: Bool) {
        if isLifted {
            if self.liftedDisplayLink == nil {
                self.liftedDisplayLink = SharedDisplayLinkDriver.shared.add(
                    framesPerSecond: .max
                ) { [weak self] _ in
                    guard let self else { return }
                    self.updateLiftedLensPosition()
                }
            }
        } else if let liftedDisplayLink = self.liftedDisplayLink {
            self.liftedDisplayLink = nil
            liftedDisplayLink.invalidate()
        }
    }
}
