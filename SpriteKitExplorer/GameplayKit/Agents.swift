/**
 
 # GameplayKit Agents
 
 A minimal setup to explore agent behaviors.
 
 Created: 20 June 2024
 Updated: 28 June 2024
 
 */

import SwiftUI
import SpriteKit
import GameplayKit

struct AgentsView: View {
    var body: some View {
        SpriteView(
            scene: AgentsScene(),
            preferredFramesPerSecond: 120,
            options: [.ignoresSiblingOrder],
            debugOptions: [.showsNodeCount, .showsFPS]
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AgentsView()
}

// MARK: - Scene

class AgentsScene: SKScene {
    
    var targetNode: AgentNode!
    var agentSystem = GKComponentSystem(componentClass: GKAgent2D.self)
    
    var contentCreated = false
    
    var center: CGPoint {
        return CGPoint(x: frame.midX, y: frame.midY)
    }
    
    var prevUpdateTime: TimeInterval = -1;
    var deltaTime: TimeInterval = 0
    
    // MARK: didMove
    
    override func didMove(to view: SKView) {
        size = view.bounds.size
        backgroundColor = .gray
        
        if !contentCreated {
            createSceneContents(view: view)
            contentCreated = true
        }
    }
    
    func createSceneContents(view: SKView) {
        targetNode = AgentNode(color: .systemYellow, radius: 30.0, position: center)
        addChild(targetNode)
        
        let width: CGFloat = 150
        let height: CGFloat = 150
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        
        // Create nodes for the corners of the rectangle
        let topLeft = GKGraphNode2D(point: vector2(Float(center.x - width / 2), Float(center.y + height / 2)))
        let topRight = GKGraphNode2D(point: vector2(Float(center.x + width / 2), Float(center.y + height / 2)))
        let bottomRight = GKGraphNode2D(point: vector2(Float(center.x + width / 2), Float(center.y - height / 2)))
        let bottomLeft = GKGraphNode2D(point: vector2(Float(center.x - width / 2), Float(center.y - height / 2)))
        
        // Connect the nodes to form a closed path
        topLeft.addConnections(to: [topRight], bidirectional: true)
        topRight.addConnections(to: [bottomRight], bidirectional: true)
        bottomRight.addConnections(to: [bottomLeft], bidirectional: true)
        bottomLeft.addConnections(to: [topLeft], bidirectional: true)
        
        // Create the path
        let path = GKPath(graphNodes: [topLeft, topRight, bottomRight, bottomLeft], radius: 10.0)
        
        // Draw the path
        let pathShape = SKShapeNode()
        let pathRect = CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
        pathShape.path = CGPath(rect: pathRect, transform: nil)
        pathShape.strokeColor = .white
        pathShape.lineWidth = 2.0
        addChild(pathShape)
        
        // Define agent behavior
        let goal0 = GKGoal(toStayOn: path, maxPredictionTime: 1)
        let goal = GKGoal(toWander: 10.0)
        let behavior = GKBehavior(goals: [goal0, goal], andWeights: [1, 1])
        targetNode.agent.maxSpeed = 150
        targetNode.agent.maxAcceleration = 150
        targetNode.agent.behavior = behavior
        agentSystem.addComponent(targetNode.agent)
    }
    
    var bullets: [GKAgent] = []
    
    func createBullet(position: CGPoint) {
        let bullet = AgentNode(color: SKColor.systemRed, radius: 5, position: position)
        bullet.agent.maxSpeed = 150
        bullet.agent.maxAcceleration = 150
        bullets.append(bullet.agent)
        addChild(bullet)
        
        let _ = GKGoal(toCohereWith: bullets, maxDistance: 1, maxAngle: 1)
        let goal2 = GKGoal(toInterceptAgent: targetNode.agent, maxPredictionTime: 10)
        let behavier = GKBehavior(goal: goal2, weight: 1)
        bullet.agent.behavior = behavier
        agentSystem.addComponent(bullet.agent)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if (prevUpdateTime < 0) {
            prevUpdateTime = currentTime
        }
        deltaTime = currentTime - prevUpdateTime
        prevUpdateTime = currentTime
        
        agentSystem.update(deltaTime: deltaTime)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            createBullet(position: touchLocation)
        }
    }
}

// MARK: - GKAgent

class AgentNode: SKNode, GKAgentDelegate {
    
    let agent: GKAgent2D
    
    init(color: SKColor, radius: CGFloat, position: CGPoint) {
        var points = [CGPoint]()
        
        for degree in [0.0, 120.0, 240.0] as [Float] {
            let radian = CGFloat(GLKMathDegreesToRadians(degree))
            let x = cos(radian) * radius
            let y = sin(radian) * radius
            points.append(CGPoint(x: x, y: y))
        }
        
        let shape = SKShapeNode(points: &points, count: points.count)
        shape.fillColor = color
        shape.strokeColor = SKColor.clear
        
        let circle = SKShapeNode(circleOfRadius: 2.0)
        circle.strokeColor = SKColor.clear
        circle.fillColor = SKColor.yellow
        circle.position = CGPoint(x: points[0].x, y: points[0].y)
        
        agent = GKAgent2D()
        agent.position = vector_float2(x: Float(position.x), y: Float(position.y))
        agent.radius = Float(radius)
        agent.maxSpeed = 50.0
        agent.maxAcceleration = 20.0
        
        super.init()
        self.position = position
        
        addChild(shape)
        addChild(circle)
        
        agent.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func agentWillUpdate(_ agent: GKAgent) {
        
    }
    
    func agentDidUpdate(_ agent: GKAgent) {
        guard let agent = agent as? GKAgent2D else { return }
        self.position = CGPoint(x: CGFloat(agent.position.x), y: CGFloat(agent.position.y))
        self.zRotation = CGFloat(agent.rotation)
    }
}
