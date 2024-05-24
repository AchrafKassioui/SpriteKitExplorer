/**
 
 # SKVideoNode with AVPlayer
 
 Created: 22 March 2024
 
 */

import SwiftUI
import SpriteKit
import AVFoundation

struct AVPlayerView: View {
    var myScene = AVPlayerScene()
    
    var body: some View {
        ZStack {
            SpriteView(
                scene: myScene,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsNodeCount, .showsDrawCount, .showsFPS]
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    AVPlayerView()
}

class AVPlayerScene: SKScene {
    
    // MARK: Scene variables
    
    /// Video player settings
    var player: AVPlayer?
    var smoothScrubber: AppleSmoothScrubber?
    var playbackMaxRate: Float = 4
    
    /// video player state
    var playbackRate: Float = 1
    var isPlaying = false
    
    /// Touch handling state
    var isDraggingRateThumb = false
    var isDraggingSeekThumb = false
    var initialRateThumbOffset: CGPoint?
    var initialSeekThumbOffset: CGPoint?
        
    /// General UI
    var padding: CGFloat = 20
    
    // MARK: - Scene setup
    override func sceneDidLoad() {
        addVideoNode()
    }
    
    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        size = view.bounds.size
        scaleMode = .resizeFill
        backgroundColor = .darkGray
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        let physicsBoundaries = CGRect(
            x: -view.frame.width / 2,
            y: -view.frame.height / 2,
            width: view.frame.width,
            height: view.frame.height
        )
        physicsBody = SKPhysicsBody(edgeLoopFrom: physicsBoundaries)
        setupCamera()
        createPlaybackRateUI()
        createPlaybackSeekUI()
        createPlaybackUI()
        createImageFiltersUI()
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        camera.name = "camera"
        let viewSize = view?.bounds.size
        camera.xScale = (viewSize!.width / size.width)
        camera.yScale = (viewSize!.height / size.height)
        addChild(camera)
        self.camera = camera
        camera.setScale(1)
    }
    
    // MARK: - AVPlayer
    func addVideoNode() {
        /// ⚠️ video file should be included like any file, NOT in the Assets catalog
        guard let filePath = Bundle.main.path(forResource: "Cars on Bridge - Legio Seven - SD", ofType: "mp4") else {
            print("Video file not found.")
            return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        self.player = AVPlayer(url: fileURL)
        guard let player = self.player else { return }
        
        /// setup video scrubber
        smoothScrubber = AppleSmoothScrubber(player: player)

        
        /// Add looping behavior
        if let playerItem = player.currentItem {
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil) { _ in
                player.seek(to: .zero)
                player.play()
                player.rate = self.playbackRate
            }
        }

        /// setup SpriteKit video node
        let videoNode = SKVideoNode(avPlayer: player)
        videoNode.name = "video-node"
        videoNode.setScale(1)
        //videoNode.zRotation = .pi * -0.5
        
        //let action = SKAction.rotate(byAngle: .pi * 2, duration: 10)
        //videoNode.run(SKAction.repeatForever(action))
        
        /// label for video credit
        let label = SKLabelNode(text: "Legio Seven")
        label.position.y = -200
        addChild(label)
        
        /// Core Image filters
        let effectNode = SKEffectNode()
        effectNode.name = "video-effectNode"
        effectNode.addChild(videoNode)
        effectNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 270, height: 480))
        addChild(effectNode)
    }
    
    // MARK: - Play/Pause
    func createPlaybackUI() {
        guard let view = view else { return }
        
        let iconTexture = SKTexture(imageNamed: "play.fill")
        let icon = SKSpriteNode(texture: iconTexture, size: CGSize(width: 16, height: 16))
        icon.name = "playback-button-icon"
        
        let button = SKShapeNode(circleOfRadius: 30)
        button.name = "playback-button"
        button.strokeColor = SKColor(white: 0, alpha: 0.6)
        button.fillColor = SKColor(white: 1, alpha: 1)
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom
        
        button.addChild(icon)
        addChild(button)
    }
    
    func handlePlayPause(_ touchedNodes: [SKNode]) {
        for node in touchedNodes {
            if node.name == "playback-button" {
                guard let player = player else { return }
                
                if isPlaying {
                    player.pause()
                    if let icon = node.childNode(withName: "playback-button-icon") as? SKSpriteNode {
                        icon.texture = SKTexture(imageNamed: "play.fill.white")
                        icon.colorBlendFactor = 1
                        icon.color = .black
                    }
                    isPlaying = false
                } else {
                    player.play()
                    player.rate = playbackRate
                    if let icon = node.childNode(withName: "playback-button-icon") as? SKSpriteNode {
                        icon.texture = SKTexture(imageNamed: "pause.fill.white")
                        icon.colorBlendFactor = 1
                        icon.color = .black
                    }
                    isPlaying = true
                }
            }
        }
    }
    
    // MARK: - Video scrubber
    func createPlaybackSeekUI() {
        guard let view = view else { return }
        
        let label = SKLabelNode()
        label.text = "00:00"
        label.name = "playback-seek-thumb-label"
        label.position.y = -6
        label.fontName = "GillSans-SemiBold"
        label.fontSize = 16
        label.fontColor = SKColor(white: 0, alpha: 1)
        
        let thumb = SKShapeNode(rectOf: CGSize(width: 60, height: 60), cornerRadius: 30)
        thumb.name = "playback-seek-thumb"
        thumb.strokeColor = SKColor(white: 0, alpha: 0.6)
        thumb.fillColor = SKColor(white: 1, alpha: 1)
        
        let track = SKShapeNode(rectOf: CGSize(width: 240, height:6), cornerRadius: 3)
        track.name = "playback-seek-track"
        track.lineWidth = 0
        track.fillColor = SKColor(white: 1, alpha: 0.6)
        track.position.x = view.bounds.width / 2 - track.frame.width / 2 - view.safeAreaInsets.right - padding
        track.position.y = view.bounds.height / -2 + track.frame.height / 2 + view.safeAreaInsets.bottom + padding + 86
        
        thumb.addChild(label)
        track.addChild(thumb)
        addChild(track)
    }
    
    func handleSeekSlider(_ touch: UITouch, with event: UIEvent?) {
        guard let offset = initialSeekThumbOffset,
              let seekTrack = self.childNode(withName: "playback-seek-track"),
              let seekThumb = seekTrack.childNode(withName: "playback-seek-thumb"),
              let seekLabel = seekThumb.childNode(withName: "playback-seek-thumb-label") as? SKLabelNode else { return }
        
        let locationInTrack = touch.location(in: seekTrack)
        
        /// Clamp the values to the track bounds
        let lowerBound = -seekTrack.frame.size.width / 2
        let upperBound = seekTrack.frame.size.width / 2
        let allowedPosition = max(lowerBound, min(locationInTrack.x - offset.x, upperBound))
        
        seekThumb.position.x = allowedPosition
        
        let normalizedValue = Float((allowedPosition - lowerBound) / (upperBound - lowerBound))
        
        /// seek video
        let duration = player?.currentItem?.duration ?? CMTime.zero
        let durationInSeconds = CMTimeGetSeconds(duration)
        let seekTimeInSeconds = durationInSeconds * Double(normalizedValue)
        let newChaseTime = CMTimeMakeWithSeconds(seekTimeInSeconds, preferredTimescale: 600)

        //smoothScrubber?.seek(to: newChaseTime)
        smoothScrubber?.player.currentItem?.audioTimePitchAlgorithm = .timeDomain
        smoothScrubber?.stopPlayingAndSeekSmoothlyToTime(newChaseTime: newChaseTime)
        
        /// UI
        seekLabel.text = String(format: "%02d:%02d", Int(newChaseTime.seconds) / 60, Int(newChaseTime.seconds) % 60)
    }
    
    func updateSeekerPosition() {
        guard let player = player,
              let duration = player.currentItem?.duration,
              CMTimeGetSeconds(duration) > 0 else {
            return
        }
        
        // Calculate the normalized current time
        let currentTime = CMTimeGetSeconds(player.currentTime())
        let totalDuration = CMTimeGetSeconds(duration)
        let normalizedTime = currentTime / totalDuration
        
        // Assuming your seek track's width is set and known
        guard let seekTrack = self.childNode(withName: "playback-seek-track"),
              let seekThumb = seekTrack.childNode(withName: "playback-seek-thumb") else { return }
        
        let trackWidth = seekTrack.frame.size.width
        let lowerBound = -trackWidth / 2
        let upperBound = trackWidth / 2
        
        // Calculate the new position of the thumb based on the current time
        let newPositionX = lowerBound + CGFloat(normalizedTime) * trackWidth
        // Ensure the position does not exceed the track bounds
        seekThumb.position.x = max(lowerBound, min(newPositionX, upperBound))
        
        // update the label with the current time
        if let seekLabel = seekThumb.childNode(withName: "playback-seek-thumb-label") as? SKLabelNode {
            let currentTimeText = String(format: "%02d:%02d", Int(currentTime) / 60, Int(currentTime) % 60)
            seekLabel.text = currentTimeText
        }
    }
    
    // MARK: - Playback speed
    func createPlaybackRateUI() {
        guard let view = view else { return }
        
        let thumb = SKShapeNode(circleOfRadius: 30)
        thumb.name = "playback-rate-thumb"
        thumb.strokeColor = SKColor(white: 0, alpha: 0.6)
        thumb.fillColor = SKColor(white: 1, alpha: 1)
        
        let label = SKLabelNode()
        label.text = "×\(String(playbackRate))"
        label.name = "playback-rate-thumb-label"
        label.position.y = -6
        label.fontName = "GillSans-SemiBold"
        label.fontSize = 16
        label.fontColor = SKColor(white: 0, alpha: 1)
        
        let track = SKShapeNode(rectOf: CGSize(width: 6, height: 180), cornerRadius: 3)
        track.name = "playback-rate-track"
        track.strokeColor = SKColor(white: 0, alpha: 0.6)
        track.fillColor = SKColor(white: 1, alpha: 0.6)
        
        let container = SKShapeNode(rectOf: CGSize(width: 60, height: 180), cornerRadius: 3)
        container.name = "playback-rate-container"
        container.lineWidth = 0
        container.fillColor = SKColor(white: 1, alpha: 0)
        container.position.x = view.bounds.width / -2 + container.frame.width / 2 + view.safeAreaInsets.left + padding
        container.position.y = view.bounds.height / -2 + container.frame.height / 2 + view.safeAreaInsets.bottom + padding
        
        thumb.addChild(label)
        track.addChild(thumb)
        container.addChild(track)
        addChild(container)
    }
    
    func handleRateSlider(_ touch: UITouch, with event: UIEvent?) {
        guard let offset = initialRateThumbOffset,
              let rateTrack = self.childNode(withName: "//playback-rate-track") as? SKShapeNode,
              let rateThumb = rateTrack.childNode(withName: "playback-rate-thumb") else { return }
        
        let locationInTrack = touch.location(in: rateTrack)
        
        /// Clamp the thumb y position within the track bounds
        let minY = -rateTrack.frame.size.height / 2
        let maxY = rateTrack.frame.size.height / 2
        let newY = max(minY, min(locationInTrack.y - offset.y, maxY))
        
        rateThumb.position.y = newY
        
        /// map thumb position to [0, 1]
        let normalizedValue = Float((newY - minY) / (maxY - minY))
        playbackRate = normalizedValue * playbackMaxRate
        
        /// use rounded values
        let roundedValue = round(playbackRate * 10) / 10
        playbackRate = roundedValue
        player?.rate = playbackRate
        
        /// UI: update the label text
        if let thumbLabel = rateThumb.childNode(withName: "playback-rate-thumb-label") as? SKLabelNode {
            thumbLabel.text = "×\(String(roundedValue))"
        }
    }
    
    // MARK: - Image Filters
    
    func createImageFiltersUI() {
        guard let view = view else { return }
        
        let iconTexture = SKTexture(imageNamed: "camera.filters")
        let icon = SKSpriteNode(texture: iconTexture, size: CGSize(width: 16, height: 16))
        icon.name = "image-filter-button-icon"
        
        let button = SKShapeNode(circleOfRadius: 30)
        button.name = "image-filter-button"
        button.strokeColor = SKColor(white: 0, alpha: 0.6)
        button.fillColor = SKColor(white: 1, alpha: 1)
        button.position.y = -view.bounds.height / 2 + button.frame.height / 2 + view.safeAreaInsets.bottom
        button.position.x = button.frame.width + padding
        
        button.addChild(icon)
        addChild(button)
    }
    
    func applyFilter(_ touchedNodes: [SKNode]) {
        for node in touchedNodes {
            if node.name == "image-filter-button" {
                guard let effectNode = scene?.childNode(withName: "//video-effectNode") as? SKEffectNode else { return }
                if effectNode.filter == nil {
                    let myFilter = MyFilters.gaussianBlur(radius: 20)
                    effectNode.filter = ChainCIFilter(filters: [myFilter])
                } else {
                    effectNode.filter = nil
                }
            }
        }
    }
    
    // MARK: - update
    
    override func update(_ currentTime: TimeInterval) {
        if !isDraggingSeekThumb {
            updateSeekerPosition()
        }
    }
    
    // MARK: - Touch events
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            let touchedNodes = nodes(at: touchLocation)
            
            handlePlayPause(touchedNodes)
            applyFilter(touchedNodes)
            
            for node in touchedNodes {
        
                if node.name == "playback-rate-thumb" {
                    isDraggingRateThumb = true
                    
                    let thumbLocation = node.position
                    let touchLocationInTrack = touch.location(in: node.parent!)
                    initialRateThumbOffset = CGPoint(x: touchLocationInTrack.x - thumbLocation.x, y: touchLocationInTrack.y - thumbLocation.y)
                }
                
                if node.name == "playback-seek-thumb" {
                    isDraggingSeekThumb = true
                    
                    let thumbLocation = node.position
                    let touchLocationInTrack = touch.location(in: node.parent!)
                    initialSeekThumbOffset = CGPoint(x: touchLocationInTrack.x - thumbLocation.x, y: touchLocationInTrack.y - thumbLocation.y)
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if isDraggingRateThumb { handleRateSlider(touch, with: event) }
            if isDraggingSeekThumb { handleSeekSlider(touch, with: event) }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isDraggingRateThumb = false
        isDraggingSeekThumb = false
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}


/**
 
 A video scrubber from GitHub
 https://gist.github.com/shaps80/ac16b906938ad256e1f47b52b4809512
 
 */

class SmoothScrubber {
    let player: AVPlayer?
    private var isSeekInProgress = false
    private var chaseTime = CMTime.zero
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    public func seek(to time: CMTime) {
        seekSmoothlyToTime(newChaseTime: time)
    }
    
    private func seekSmoothlyToTime(newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    private func trySeekToChaseTime() {
        guard player?.status == .readyToPlay else { return }
        actuallySeekToTime()
    }
    
    private func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        
        player?.seek(to: seekTimeInProgress, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            guard let `self` = self else { return }
            
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
            } else {
                self.trySeekToChaseTime()
            }
        }
    }
}

/**
 
 A video scrubber from an Apple code example
 https://developer.apple.com/library/archive/qa/qa1820/_index.html
 
 */
class AppleSmoothScrubber {
    let player: AVPlayer
    var isSeekInProgress = false
    var chaseTime = CMTime.zero
    var playerCurrentItemStatus: AVPlayerItem.Status = .unknown
    
    init(player: AVPlayer) {
        self.player = player
    }
    
    func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) {
        player.pause()
        
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime;
            
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    func trySeekToChaseTime() {
        guard player.status == .readyToPlay else { return }
        actuallySeekToTime()
    }
    
    /*
    /// original Apple version of `trySeekToChaseTime`
    func trySeekToChaseTime() {
        if playerCurrentItemStatus == .unknown {
            // wait until item becomes ready (KVO player.currentItem.status)
        } else if playerCurrentItemStatus == .readyToPlay {
            print("yo")
            actuallySeekToTime()
        }
    }
    */
    
    func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player.seek(to: seekTimeInProgress, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero, completionHandler: { (isFinished:Bool) -> Void in
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
                self.player.play()
            } else {
                self.trySeekToChaseTime()
            }
        })
    }
}

