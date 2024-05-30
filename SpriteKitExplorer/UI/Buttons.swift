//
//  Buttons.swift
//  SpriteKitExplorer
//
//  Created by Achraf Kassioui on 8/5/2024.
//

import SpriteKit

// MARK: - Toggle switch
/**
 
 Toggle switch button
 - On touch began, the toggle is active
 - On touch end, the toggle is inactive
 
 */

class ToggleSwitch: SKSpriteNode {

    /// Toggle settings
    var buttonSize = CGSize(width: 60, height: 60)
    var backgroundColor = SKColor.darkGray
    
    /// Toggle components
    var icon: SKSpriteNode
    var iconON: SKTexture
    var iconOFF: SKTexture
    var isOn = false
    
    let onTouchBegan: () -> Void
    let onTouchEnded: () -> Void
    
    init(iconON: SKTexture, iconOFF: SKTexture, onTouchBegan: @escaping () -> Void, onTouchEnded: @escaping () -> Void, isOn: Bool? = false) {
        self.iconON = iconON
        self.iconOFF = iconOFF
        self.isOn = isOn ?? false
        self.onTouchBegan = onTouchBegan
        self.onTouchEnded = onTouchEnded
        
        self.icon = SKSpriteNode(texture: self.isOn ? self.iconON : self.iconOFF)
        self.icon.isUserInteractionEnabled = false
        
        super.init(texture: nil, color: backgroundColor, size: self.buttonSize)
        self.isUserInteractionEnabled = true
        self.addChild(self.icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func enableToggle() {
        onTouchBegan()
        self.icon.texture = iconON
    }
    
    func disableToggle() {
        onTouchEnded()
        self.icon.texture = iconOFF
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            enableToggle()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            disableToggle()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// MARK: - Physical Button

protocol PhysicalButtonDelegate: AnyObject {
    func buttonTouched(button: ButtonPhysical, touch: UITouch)
}

class ButtonPhysical: SKSpriteNode {
    
    /// dependencies
    weak var view: SKView?
    weak var delegate: PhysicalButtonDelegate?
    
    /// state
    var isActive = false
    var iconActive: SKTexture
    var iconInactive: SKTexture
    var label: SKLabelNode?
    var labelInactive: String
    var labelActive: String
    
    /// style
    var icon = SKSpriteNode()
    
    enum ButtonShape {
        case round
        case square
    }
    
    enum Theme {
        case light
        case dark
    }
    
    var buttonShape: ButtonShape
    
    var theme: Theme {
        didSet {
            setStyle(shape: self.buttonShape)
        }
    }
    
    var iconSize: CGSize
    var activeColor: SKColor = .white
    var inactiveColor: SKColor = .white
    
    /// physics
    var isPhysical: Bool
    var verticalGap: CGFloat = 2
    var horizontalGap: CGFloat = 0
    var mass: CGFloat = 0.1
    var charge: CGFloat = 10
    
    /// button action
    let onTouch: () -> Void
    
    /**
     
     ## initialization
     
     */
    init(
        view: SKView,
        shape: ButtonShape,
        size: CGSize,
        iconInactive: SKTexture,
        iconActive: SKTexture,
        labelInactive: String? = "",
        labelActive: String? = "",
        iconSize: CGSize,
        theme: Theme,
        isPhysical: Bool,
        onTouch: @escaping () -> Void
    ) {
        self.view = view
        self.buttonShape = shape
        self.theme = theme
        self.onTouch = onTouch
        self.iconInactive = iconInactive
        self.iconActive = iconActive
        self.labelInactive = labelInactive ?? ""
        self.labelActive = labelActive ?? ""
        self.iconSize = iconSize
        self.isPhysical = isPhysical
        
        /// icon
        self.icon.texture = iconInactive
        self.icon.size = iconSize
        self.icon.colorBlendFactor = 1
        self.icon.isUserInteractionEnabled = false
        self.icon.zPosition = 1
        
        /// the actual sprite node button
        super.init(texture: nil, color: .clear, size: size)
        self.isUserInteractionEnabled = true
        self.addChild(self.icon)
        
        if !self.labelActive.isEmpty && !self.labelInactive.isEmpty {
            self.label = SKLabelNode(text: labelInactive)
            self.label?.fontColor = icon.color
            self.label?.fontSize = 10
            self.label?.verticalAlignmentMode = .center
            self.label?.horizontalAlignmentMode = .center
            if let label = self.label {
                self.addChild(label)
                label.position.y = -self.size.height/2 + 4
            }
        } else {
            self.label = nil
        }
        
        /// apply initial style based on the theme
        setStyle(shape: self.buttonShape)
        
        /// create physics body
        if isPhysical { setupPhysics() }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     
     ## Physics Body
     
     */
    func setupPhysics() {
        let bodyWidth = self.size.width + horizontalGap
        let bodyHeight = self.size.height + verticalGap
        switch self.buttonShape {
        case .round:
            self.physicsBody = SKPhysicsBody(circleOfRadius: bodyHeight/2)
        case .square:
            self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: bodyWidth, height: bodyHeight))
        }
        self.physicsBody?.mass = mass
        self.physicsBody?.charge = charge
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.linearDamping = 0
    }
    
    /**
     
     ## Button Style
     
     */
    func setStyle(shape: ButtonShape) {
        guard let view = self.view else { return }
        
        //let patternColor: SKColor
        let strokeColor: SKColor
        let iconColor: SKColor
        
        switch theme {
        case .light:
            strokeColor = SKColor(white: 0, alpha: 0.6)
            //patternColor = SKColor(white: 0, alpha: 0.3)
            iconColor = SKColor(white: 0, alpha: 0.8)
        case .dark:
            strokeColor = SKColor(white: 0, alpha: 0.8)
            //patternColor = SKColor(white: 0, alpha: 0.8)
            iconColor = self.inactiveColor
        }
        
        /// create a shape and get a texture from it
        var shapeNode = SKShapeNode()
        switch shape {
        case .round:
            shapeNode = SKShapeNode(circleOfRadius: size.width/2)
        case .square:
            shapeNode = SKShapeNode(rectOf: size, cornerRadius: 0)
        }
        shapeNode.fillColor = .clear
        shapeNode.lineWidth = 0
        shapeNode.strokeColor = strokeColor
        //shapeNode.fillTexture = generateDotPatternTexture(size: size, color: patternColor, pattern: .regular, dotSize: 1)
        self.texture = view.texture(from: shapeNode)
        self.icon.color = iconColor
    }
    
    /**
     
     ## Internal Logic
     
     */
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    private var isHot = false {
        didSet {
            updateButtonAppearance()
        }
    }
    
    private let shrinkAction = SKAction.scale(to: 0.9, duration: 0.064)
    private let restoreAction = SKAction.scale(to: 1, duration: 0.064)
    
    private func updateButtonAppearance() {
        if isHot {
            self.run(shrinkAction)
        } else {
            self.run(restoreAction)
        }
    }
    
    private func trigger() {
        isHot = true
        isActive.toggle()
        icon.texture = isActive ? iconActive : iconInactive
        icon.color = isActive ? activeColor : inactiveColor
        label?.text = isActive ? labelActive : labelInactive
        onTouch()
        hapticFeedback.impactOccurred()
    }
    
    private func isTouchInside(_ touch: UITouch) -> Bool {
        var isInside = false
        if let parent = self.parent {
            let location = touch.location(in: parent)
            isInside = self.contains(location)
        }
        return isInside
    }
    
    /**
     
     ## Setup Touch Interaction
     
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for touch in touches {
            trigger()
            delegate?.buttonTouched(button: self, touch: touch)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            isHot = isTouchInside(touch)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for _ in touches {
            isHot = false
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchesEnded(touches, with: event)
    }
}

// MARK: - Button with dot pattern

class ButtonWithDotPattern: SKShapeNode {
    
    var icon: SKSpriteNode
    private let onAction: () -> Void
    private var isHot = false {
        didSet {
            updateButtonAppearance()
        }
    }
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    /// initialization
    init(
        size: CGSize,
        icon: SKTexture,
        onAction: @escaping () -> Void
    ) {
        self.onAction = onAction
        
        /// icon
        self.icon = SKSpriteNode(texture: icon)
        self.icon.colorBlendFactor = 1
        self.icon.color = SKColor(white: 0, alpha: 1)
        self.icon.size = CGSize(width: 24, height: 24)
        self.icon.isUserInteractionEnabled = false
        
        /// shape
        super.init()
        self.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), transform: nil)
        self.fillTexture = generateDotPatternTexture(size: size, color: SKColor(white: 0, alpha: 1), pattern: .staggered)
        self.strokeColor = SKColor(white: 0, alpha: 1)
        self.fillColor = SKColor(white: 1, alpha: 0.4)
        self.isUserInteractionEnabled = true
        self.addChild(self.icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// interaction
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isHot = true
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            isHot = self.contains(location)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if isHot && self.contains(location) {
                onAction()
                hapticFeedback.impactOccurred()
            }
        }
        isHot = false
    }
    
    private func updateButtonAppearance() {
        if isHot {
            self.run(SKAction.scale(to: 0.89, duration: 0.032))
        } else {
            self.run(SKAction.scale(to: 1, duration: 0.032))
        }
    }
}

// MARK: - Button with icon

class ButtonWithIconAndPattern: SKShapeNode {
    
    /// a call back function to execute
    /// the function to execute is passed as an argument during initialization
    let onTouch: () -> Void
    
    enum ButtonState {
        case base
        case active
    }
    
    private var buttonState: ButtonState = .base
    private let iconName1: String
    private let iconName2: String
    
    private let icon: SKSpriteNode
    
    /// initialization
    init(
        size: CGSize,
        icon1: String,
        icon2: String,
        iconSize: CGSize,
        onTouch: @escaping () -> Void
    ) {
        self.onTouch = onTouch
        self.iconName1 = icon1
        self.iconName2 = icon2
        
        /// button icon
        self.icon = SKSpriteNode(imageNamed: icon1)
        self.icon.size = iconSize
        self.icon.colorBlendFactor = 1
        self.icon.color = SKColor(white: 0, alpha: 1)
        self.icon.isUserInteractionEnabled = false
        
        /// button shape
        super.init()
        self.path = CGPath(ellipseIn: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2), size: size), transform: nil)
        
        /// styling
        let dotTexture = generateDotPatternTexture(size: size, color: SKColor(white: 0, alpha: 1), pattern: .staggered, cornerRadius: size.width/2)
        fillTexture = dotTexture
        strokeColor = SKColor(white: 0, alpha: 1)
        fillColor = SKColor(white: 1, alpha: 0.4)
        
        isUserInteractionEnabled = true
        addChild(icon)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// interaction
    private func updateIcon() {
        let iconName = buttonState == .base ? iconName1 : iconName2
        let iconColor: SKColor = buttonState == .base ? SKColor(white: 0, alpha: 1) : SKColor.systemRed
        icon.texture = SKTexture(imageNamed: iconName)
        icon.color = iconColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        buttonState = buttonState == .base ? .active : .base
        updateIcon()
        onTouch()
    }
}

// MARK: - Button with label
/**
 
 A convenience class to create UI buttons in SpriteKit.
 
 Parameters:
 - Parameter size: the rectangular size of the button
 - Parameter textContent: the button label
 - Parameter onTouch: a function to execute whenever the button is touched. A touch toggles the `isActive` property
 
 */

class ButtonWithLabel: SKShapeNode {
    
    /// properties
    var isActive = false
    let labelNode: SKLabelNode
    let textColor = SKColor(white: 0, alpha: 0.8)
    let borderColor = SKColor(white: 0, alpha: 1)
    let backgroundColor = SKColor(white: 1, alpha: 0.4)
    
    let textContent: String
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    /// a function to be called when the button is touched
    let onTouch: () -> Void
    
    /// initialization
    init(size: CGSize, textContent: String, onTouch: @escaping () -> Void) {
        self.labelNode = SKLabelNode(text: textContent)
        self.textContent = textContent
        self.onTouch = onTouch
        
        /// button shape
        super.init()
        self.path = UIBezierPath(
            roundedRect: CGRect(origin: CGPoint(x: -size.width/2, y: -size.height/2),size: size),
            cornerRadius: 12
        ).cgPath
        strokeColor = borderColor
        fillColor = backgroundColor
        isUserInteractionEnabled = true
        
        /// button label
        self.labelNode.fontName = "GillSans-SemiBold"
        self.labelNode.fontColor = textColor
        self.labelNode.fontSize = 18
        self.labelNode.verticalAlignmentMode = .center
        self.labelNode.isUserInteractionEnabled = false
        self.addChild(labelNode)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var pulseAnimation = SKAction.sequence([
        SKAction.scale(to: 1.2, duration: 0.05),
        SKAction.scale(to: 0.95, duration: 0.05),
        SKAction.scale(to: 1, duration: 0.02)
    ])
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.isActive.toggle()
        self.run(pulseAnimation)
        hapticFeedback.impactOccurred()
        onTouch()
    }
    
}

// MARK: Button with Icon and Label

class ButtonWithIconAndLabel: SKShapeNode {
    
    init(name: String, size: CGSize, icon: String, parent: SKNode, label: String? = nil) {
        super.init()
        
        let origin = CGPoint(x: -size.width / 2, y: -size.height / 2)
        let rect = CGRect(origin: origin, size: size)
        let cornerRadius: CGFloat = 7.0
        self.path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        self.name = name
        self.lineWidth = 1
        self.strokeColor = .black.withAlphaComponent(0.6)
        self.fillColor = SKColor.white.withAlphaComponent(0.6)
        
        /// add the icon as a child
        let iconNode = SKSpriteNode(imageNamed: icon)
        iconNode.zPosition = self.zPosition + 1
        self.addChild(iconNode)
        
        /// if a label is provided, add it below the icon
        if let labelText = label {
            let labelNode = SKLabelNode(text: labelText)
            labelNode.fontName = "SFMono-Regular"
            labelNode.fontSize = 50
            labelNode.setScale(0.2)
            labelNode.fontColor = UIColor.black.withAlphaComponent(0.6)
            
            /// adjust the label's position based on the icon's size
            labelNode.position = CGPoint(x: 0, y: -(size.height / 2) + 10)
            labelNode.zPosition = self.zPosition + 2
            iconNode.position.y = 8
            
            self.addChild(labelNode)
        }
        
        parent.addChild(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
