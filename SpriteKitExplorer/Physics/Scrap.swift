import SwiftUI
import SpriteKit

/**
 
 # Scrap
 
 This is a test scene to debug an issue with user touch detection on a node with physics body.
 The problem appears when we make a subclass of a node, then instantiate it in a scene, and want to call a function inside the subclass from the parent scene.
 
 In the following code, inside the subclass:
 
 ```
 override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
     for touch in touches {
        let location = touch.location(in: self)
        isHot = self.contains(location)
        print(isHot)
     }
 }
 ```
 `isHot` never returns true. `self.contains(location)` does not work.

 We have to replace the code with:
 ```
 override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
     for touch in touches {
        let locationInParent = self.parent!.convert(touch.location(in: self), from: self)
        isHot = self.contains(locationInParent)
        print(isHot)
     }
 }
 ```
 Now `isHot` is correctly updated.
 
 Update: it might be simpler than that. Inside a class that will be instantiated inside a scene, we should check location directly relative to the parent:
 ```
 override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
     for touch in touches {
         let location = touch.location(in: self.parent!)
         isHot = self.contains(location)
     }
 }
 ```
 The parent being the scene.
 
 Resolved with the help of Google Gemini Advanced. I need further investigation to understand the issue better. Not sure whether it's expected behavior or a SpriteKit bug.
 
 Achraf Kassioui
 Created: 24 April 2024
 Updated: 24 April 2024
 
 */

// MARK: - Live preview

struct ScrapView: View {
    @State private var sceneId = UUID()
    
    var body: some View {
        SpriteView(
            scene: ScrapSceneWithoutInstance(),
            options: [.ignoresSiblingOrder, .shouldCullNonVisibleNodes],
            debugOptions: [.showsFPS, .showsDrawCount, .showsNodeCount, .showsPhysics]
        )
        /// force recreation using the unique ID
        .id(sceneId)
        .onAppear {
            /// generate a new ID on each appearance
            sceneId = UUID()
        }
        //.ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    ScrapView()
}

// MARK: Test scene with a physical button created directly in the scene

class ScrapSceneWithoutInstance: SKScene {
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        backgroundColor = .white
        physicsWorld.speed = 1
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        createBoundaries(view: view)
        createButton()
    }
    
    var spriteButton = SKSpriteNode()
    
    func createButton() {
        spriteButton = SKSpriteNode(color: .red, size: CGSize(width: 60, height: 60))
        spriteButton.name = "sprite-button"
        spriteButton.physicsBody = SKPhysicsBody(rectangleOf: spriteButton.size)
        addChild(spriteButton)
    }
    
    func doSomething() {
        print("action called from button")
    }
    
    func createBoundaries(view: SKView) {
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        
        let physicalFrame = SKShapeNode(rect: physicsBoundaries)
        physicalFrame.lineWidth = 3
        physicalFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        physicalFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicalFrame.zPosition = -1
        addChild(physicalFrame)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if spriteButton.contains(location) {
                print("button touched")
            }
        }
    }
    
    /*
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let foremostNode = atPoint(location)
            if foremostNode.name == "sprite-button" {
                print("button touched")
            }
        }
    }
    */
    
}

// MARK: Test scene with an instance of a button class

class ScrapScene: SKScene {
    
    var sprite = SKSpriteNode()
    
    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        size = view.bounds.size
        scaleMode = .resizeFill
        view.isMultipleTouchEnabled = true
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        
        createButton()
        createBoundaries(view: view)
    }
    
    func createButton() {
        sprite = CustomButton(
            onAction: doSomething
        )
        sprite.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        addChild(sprite)
    }
    
    func doSomething() {
        print("action called from button")
    }
    
    func createBoundaries(view: SKView) {
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        
        let physicalFrame = SKShapeNode(rect: physicsBoundaries)
        physicalFrame.lineWidth = 3
        physicalFrame.strokeColor = SKColor(white: 0, alpha: 0.9)
        physicalFrame.physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        physicalFrame.isUserInteractionEnabled = false
        physicalFrame.zPosition = -1
        addChild(physicalFrame)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for _ in touches {
            print("scene touched")
        }
    }
    
}

class CustomButton: SKSpriteNode {
    
    let onAction: () -> Void
    private var isHot = false {
        didSet {
            updateButtonAppearance()
        }
    }
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init(
        onAction: @escaping () -> Void
    ) {
        self.onAction = onAction
        super.init(texture: nil, color: .red, size: CGSize(width: 60, height: 60))
        self.isUserInteractionEnabled = true
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
            let locationInParent = self.parent!.convert(touch.location(in: self), from: self)
            isHot = self.contains(locationInParent)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let locationInParent = self.parent!.convert(touch.location(in: self), from: self)
            if isHot && self.contains(locationInParent) {
                onAction()
                hapticFeedback.impactOccurred()
            }
        }
        isHot = false
    }
    
    private let shrinkAction = SKAction.scale(to: 0.89, duration: 0.032)
    private let restoreAction = SKAction.scale(to: 1, duration: 0.032)
    
    private func updateButtonAppearance() {
        if isHot {
            self.run(shrinkAction)
        } else {
            self.run(restoreAction)
        }
    }
}

// MARK: - UI Container with Physics Field
/**
 
 This function creates several buttons, a container, and a drag handle.
 It's an experiment for building UI layout using physics. In this case, buttons are distributed inside the container using a physics field and position constraints.
 
 Created: 12 May 2024
 Updated: 15 May 2024
 
 */

func createUI(in parent: SKNode, with view: SKView) {
    let strokeColor = SKColor(white: 0, alpha: 0.6)
    let fillColor = SKColor(white: 0, alpha: 0.3)
    let theme = ButtonPhysical.Theme.dark
    let containerSize = CGSize(width: 64, height: 320)
    
    /// drag handle
    let dragHandle = SKShapeNode(rectOf: CGSize(width: containerSize.width - 20, height: 24))
    dragHandle.name = "draggable"
    dragHandle.lineWidth = 0
    dragHandle.fillColor = .white
    dragHandle.fillTexture = generateStripedTexture(size: dragHandle.frame.size, colorA: .clear, colorB: strokeColor, stripeHeight: 3)
    dragHandle.physicsBody = SKPhysicsBody(rectangleOf: dragHandle.frame.size)
    dragHandle.physicsBody?.isDynamic = false
    //setupPhysicsCategories(node: dragHandle, as: .UIBoundary)
    parent.addChild(dragHandle)
    
    /// containement field
    let minimumRadius: Float = 3
    let field = SKFieldNode.electricField()
    //setupPhysicsCategories(node: field, as: .UIField)
    field.name = ""
    field.region = SKRegion(size: containerSize)
    field.strength = -1
    field.minimumRadius = minimumRadius
    field.falloff = -3
    field.position.y = containerSize.height/2 + dragHandle.frame.height/2 + 6
    dragHandle.addChild(field)
    
    //visualizeField(circleOfRadius: CGFloat(minimumRadius), text: "Min Radius", parent: field)
    //visualizeField(rectOfSize: containerSize, text: "UI Containment", parent: field)
    
    let perimeter = SKShapeNode(rectOf: containerSize, cornerRadius: 30)
    perimeter.lineWidth = 3
    perimeter.strokeColor = strokeColor
    perimeter.fillColor = fillColor
    perimeter.physicsBody = SKPhysicsBody(edgeLoopFrom: perimeter.path!)
    //setupPhysicsCategories(node: perimeter, as: .UIBoundary)
    field.addChild(perimeter)
    
    /// add button
    let addButton = ButtonPhysical(
        view: view,
        shape: .round,
        size: CGSize(width: 60, height: 60),
        iconInactive: SKTexture(imageNamed: "plus-icon"),
        iconActive: SKTexture(imageNamed: "plus-icon"),
        iconSize: CGSize(width: 32, height: 32),
        theme: theme,
        isPhysical: true,
        onTouch: {
            
        }
    )
    addButton.zPosition = 100
    //setupPhysicsCategories(node: addButton, as: .UIBody)
    //addButton.constraints = [createSceneConstraints(node: addButton, insideRect: perimeter)]
    addButton.position.y = 0
    parent.addChild(addButton)
    
    /// delete button
    let deleteButton = ButtonPhysical(
        view: view,
        shape: .round,
        size: CGSize(width: 60, height: 60),
        iconInactive: SKTexture(imageNamed: "trash-icon"),
        iconActive: SKTexture(imageNamed: "trash-icon"),
        iconSize: CGSize(width: 32, height: 32),
        theme: theme,
        isPhysical: true,
        onTouch: {
            
        }
    )
    deleteButton.zPosition = 100
    //setupPhysicsCategories(node: deleteButton, as: .UIBody)
    //deleteButton.constraints = [createSceneConstraints(node: deleteButton, insideRect: perimeter)]
    deleteButton.position.y = 20
    parent.addChild(deleteButton)
    
    /// reset camera button
    let resetCameraButton = ButtonPhysical(
        view: view,
        shape: .round,
        size: CGSize(width: 60, height: 60),
        iconInactive: SKTexture(imageNamed: "camera-reset-icon"),
        iconActive: SKTexture(imageNamed: "camera-reset-icon"),
        iconSize: CGSize(width: 32, height: 32),
        theme: theme,
        isPhysical: true,
        onTouch: {
        }
    )
    resetCameraButton.zPosition = 100
    //setupPhysicsCategories(node: resetCameraButton, as: .UIBody)
    //resetCameraButton.constraints = [createSceneConstraints(node: resetCameraButton, insideRect: perimeter)]
    resetCameraButton.position.y = 60
    parent.addChild(resetCameraButton)
    
    /// debug button
    let debugButton = ButtonPhysical(
        view: view,
        shape: .round,
        size: CGSize(width: 60, height: 60),
        iconInactive: SKTexture(imageNamed: "debug-icon"),
        iconActive: SKTexture(imageNamed: "debug-icon"),
        iconSize: CGSize(width: 32, height: 32),
        theme: theme,
        isPhysical: true,
        onTouch: {
            view.showsFPS.toggle()
            view.showsNodeCount.toggle()
            view.showsPhysics.toggle()
            view.showsDrawCount.toggle()
        }
    )
    debugButton.zPosition = 100
    //setupPhysicsCategories(node: debugButton, as: .UIBody)
    //debugButton.constraints = [createSceneConstraints(node: debugButton, insideRect: perimeter)]
    debugButton.position.y = 80
    parent.addChild(debugButton)
    
    /// gravity button
    let gravityButton = ButtonPhysical(
        view: view,
        shape: .round,
        size: CGSize(width: 60, height: 60),
        iconInactive: SKTexture(imageNamed: "gravity-off-icon"),
        iconActive: SKTexture(imageNamed: "gravity-icon"),
        iconSize: CGSize(width: 32, height: 32),
        theme: theme,
        isPhysical: true,
        onTouch: {
        }
    )
    gravityButton.zPosition = 100
    //setupPhysicsCategories(node: gravityButton, as: .UIBody)
    //gravityButton.constraints = [createSceneConstraints(node: gravityButton, insideRect: perimeter)]
    gravityButton.position.y = 100
    parent.addChild(gravityButton)
}
