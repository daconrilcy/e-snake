import SpriteKit

final class GameScene: SKScene {

    // MARK: - Grid config
    private let cols = 20
    private let rows = 30
    private var cellSize: CGFloat = 18

    // MARK: - Game state
    private enum Direction { case up, down, left, right }
    private var direction: Direction = .right
    private var pendingDirection: Direction = .right

    private struct GridPos: Equatable {
        var x: Int
        var y: Int
    }

    private var headPos = GridPos(x: 5, y: 10)
    private var headNode: SKSpriteNode!

    // Tick
    private let tickInterval: TimeInterval = 0.12
    private var tickActionKey = "snake.tick"

    // MARK: - Scene lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .black

        // Compute cellSize to fit screen nicely (responsive)
        let sizeByWidth = size.width / CGFloat(cols)
        let sizeByHeight = size.height / CGFloat(rows)
        cellSize = floor(min(sizeByWidth, sizeByHeight))

        setupHead()
        setupInput(in: view)
        startTick()
    }

    // MARK: - Setup
    private func setupHead() {
        headNode = SKSpriteNode(color: .green, size: CGSize(width: cellSize - 2, height: cellSize - 2))
        headNode.position = point(for: headPos)
        addChild(headNode)
    }

    private func setupInput(in view: SKView) {
        // Avoid multiple recognizers if scene reloads
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }

        let up = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        up.direction = .up

        let down = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        down.direction = .down

        let left = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        left.direction = .left

        let right = UISwipeGestureRecognizer(target: self, action: #selector(onSwipe(_:)))
        right.direction = .right

        [up, down, left, right].forEach { view.addGestureRecognizer($0) }
    }

    private func startTick() {
        removeAction(forKey: tickActionKey)
        let wait = SKAction.wait(forDuration: tickInterval)
        let step = SKAction.run { [weak self] in self?.step() }
        let loop = SKAction.repeatForever(SKAction.sequence([wait, step]))
        run(loop, withKey: tickActionKey)
    }

    // MARK: - Game loop
    private func step() {
        // Apply direction once per tick (prevents ultra-fast changes between ticks)
        direction = pendingDirection

        var next = headPos
        switch direction {
        case .up: next.y += 1
        case .down: next.y -= 1
        case .left: next.x -= 1
        case .right: next.x += 1
        }

        // Wrap-around for now (on verra collision mur après)
        if next.x < 0 { next.x = cols - 1 }
        if next.x >= cols { next.x = 0 }
        if next.y < 0 { next.y = rows - 1 }
        if next.y >= rows { next.y = 0 }

        headPos = next
        headNode.position = point(for: headPos)
    }

    // MARK: - Input
    @objc private func onSwipe(_ gr: UISwipeGestureRecognizer) {
        let newDir: Direction
        switch gr.direction {
        case .up: newDir = .up
        case .down: newDir = .down
        case .left: newDir = .left
        case .right: newDir = .right
        default: return
        }

        // Prevent instant reverse
        if isOpposite(current: direction, candidate: newDir) { return }
        pendingDirection = newDir
    }

    private func isOpposite(current: Direction, candidate: Direction) -> Bool {
        switch (current, candidate) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return true
        default:
            return false
        }
    }

    // MARK: - Grid mapping
    private func point(for pos: GridPos) -> CGPoint {
        // Center grid in scene
        let gridW = CGFloat(cols) * cellSize
        let gridH = CGFloat(rows) * cellSize

        let originX = (size.width - gridW) / 2
        let originY = (size.height - gridH) / 2

        let x = originX + (CGFloat(pos.x) + 0.5) * cellSize
        let y = originY + (CGFloat(pos.y) + 0.5) * cellSize
        return CGPoint(x: x, y: y)
    }
}