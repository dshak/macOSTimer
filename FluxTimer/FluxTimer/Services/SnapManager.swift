import AppKit

/// Manages magnetic snapping between timer windows.
/// Windows snap together when dragged within a threshold of each other's edges,
/// and snapped windows move as a group.
class SnapManager {
    enum Edge {
        case left, right, top, bottom
    }

    struct SnapConnection: Equatable {
        let windowA: ObjectIdentifier
        let windowB: ObjectIdentifier
        let sideA: Edge
        let sideB: Edge

        static func == (lhs: SnapConnection, rhs: SnapConnection) -> Bool {
            (lhs.windowA == rhs.windowA && lhs.windowB == rhs.windowB) ||
            (lhs.windowA == rhs.windowB && lhs.windowB == rhs.windowA)
        }
    }

    var snapThreshold: CGFloat = 20
    var snapGap: CGFloat = 0

    private var trackedWindows: [ObjectIdentifier: TimerWindow] = [:]
    private var connections: [SnapConnection] = []

    // Prevents recursive group-move updates
    private var isPerformingGroupMove = false

    // MARK: - Registration

    func register(_ window: TimerWindow) {
        trackedWindows[ObjectIdentifier(window)] = window
    }

    func unregister(_ window: TimerWindow) {
        let id = ObjectIdentifier(window)
        trackedWindows.removeValue(forKey: id)
        connections.removeAll { $0.windowA == id || $0.windowB == id }
    }

    // MARK: - Snap Detection (called on window move)

    /// Called when a user drags a window. Checks for snap opportunities
    /// and moves the group if the window is part of one.
    func windowDidMove(_ window: TimerWindow) {
        guard !isPerformingGroupMove else { return }

        let movingId = ObjectIdentifier(window)

        // Move group members by the same delta
        moveGroup(for: window)

        // Check for new snap opportunities with non-grouped windows
        let others = trackedWindows.filter { $0.key != movingId }
        for (otherId, otherWindow) in others {
            // Skip if already connected
            if connections.contains(where: {
                ($0.windowA == movingId && $0.windowB == otherId) ||
                ($0.windowA == otherId && $0.windowB == movingId)
            }) { continue }

            if let snap = detectSnap(moving: window, target: otherWindow) {
                applySnap(snap, moving: window, target: otherWindow)
                connections.append(snap)
            }
        }

        // Check for detachment — if window moved far enough from a connected peer
        checkDetachment(window)
    }

    // MARK: - Snap Detection Logic

    private func detectSnap(moving: NSWindow, target: NSWindow) -> SnapConnection? {
        let mf = moving.frame
        let tf = target.frame
        let movingId = ObjectIdentifier(moving)
        let targetId = ObjectIdentifier(target)

        // Vertical overlap check (windows must overlap vertically to snap horizontally)
        let vOverlap = mf.maxY > tf.minY + 10 && mf.minY < tf.maxY - 10
        // Horizontal overlap check
        let hOverlap = mf.maxX > tf.minX + 10 && mf.minX < tf.maxX - 10

        // Right edge of moving → Left edge of target
        if vOverlap && abs(mf.maxX + snapGap - tf.minX) < snapThreshold {
            return SnapConnection(windowA: movingId, windowB: targetId, sideA: .right, sideB: .left)
        }

        // Left edge of moving → Right edge of target
        if vOverlap && abs(mf.minX - snapGap - tf.maxX) < snapThreshold {
            return SnapConnection(windowA: movingId, windowB: targetId, sideA: .left, sideB: .right)
        }

        // Bottom edge of moving → Top edge of target (note: macOS Y is flipped — minY is bottom)
        if hOverlap && abs(mf.minY - snapGap - tf.maxY) < snapThreshold {
            return SnapConnection(windowA: movingId, windowB: targetId, sideA: .bottom, sideB: .top)
        }

        // Top edge of moving → Bottom edge of target
        if hOverlap && abs(mf.maxY + snapGap - tf.minY) < snapThreshold {
            return SnapConnection(windowA: movingId, windowB: targetId, sideA: .top, sideB: .bottom)
        }

        return nil
    }

    private func applySnap(_ snap: SnapConnection, moving: NSWindow, target: NSWindow) {
        var newFrame = moving.frame

        switch (snap.sideA, snap.sideB) {
        case (.right, .left):
            newFrame.origin.x = target.frame.minX - moving.frame.width - snapGap
        case (.left, .right):
            newFrame.origin.x = target.frame.maxX + snapGap
        case (.bottom, .top):
            newFrame.origin.y = target.frame.maxY + snapGap
        case (.top, .bottom):
            newFrame.origin.y = target.frame.minY - moving.frame.height - snapGap
        default:
            return
        }

        // Also align the perpendicular axis if close
        switch (snap.sideA, snap.sideB) {
        case (.right, .left), (.left, .right):
            // Align tops if close
            if abs(moving.frame.maxY - target.frame.maxY) < snapThreshold {
                newFrame.origin.y = target.frame.maxY - moving.frame.height
            } else if abs(moving.frame.minY - target.frame.minY) < snapThreshold {
                newFrame.origin.y = target.frame.minY
            }
        case (.top, .bottom), (.bottom, .top):
            // Align left edges if close
            if abs(moving.frame.minX - target.frame.minX) < snapThreshold {
                newFrame.origin.x = target.frame.minX
            } else if abs(moving.frame.maxX - target.frame.maxX) < snapThreshold {
                newFrame.origin.x = target.frame.maxX - moving.frame.width
            }
        default:
            break
        }

        isPerformingGroupMove = true
        moving.setFrame(newFrame, display: true)
        isPerformingGroupMove = false
    }

    // MARK: - Group Movement

    /// Track the last known frame for each window to compute deltas
    private var lastFrames: [ObjectIdentifier: NSRect] = [:]

    func windowWillStartDrag(_ window: TimerWindow) {
        // Snapshot all group member positions
        let group = groupMembers(for: window)
        for member in group {
            lastFrames[ObjectIdentifier(member)] = member.frame
        }
    }

    private func moveGroup(for window: TimerWindow) {
        let windowId = ObjectIdentifier(window)
        guard let lastFrame = lastFrames[windowId] else {
            lastFrames[windowId] = window.frame
            return
        }

        let dx = window.frame.origin.x - lastFrame.origin.x
        let dy = window.frame.origin.y - lastFrame.origin.y

        guard dx != 0 || dy != 0 else { return }

        let group = groupMembers(for: window)
        guard group.count > 1 else {
            lastFrames[windowId] = window.frame
            return
        }

        isPerformingGroupMove = true
        for member in group where member !== window {
            let memberId = ObjectIdentifier(member)
            var memberFrame = member.frame
            memberFrame.origin.x += dx
            memberFrame.origin.y += dy
            member.setFrame(memberFrame, display: true)
            lastFrames[memberId] = memberFrame
        }
        lastFrames[windowId] = window.frame
        isPerformingGroupMove = false
    }

    // MARK: - Detachment

    private func checkDetachment(_ window: NSWindow) {
        let windowId = ObjectIdentifier(window)
        let detachThreshold = snapThreshold * 2.5 // Need to drag further than snap to detach

        connections.removeAll { conn in
            guard conn.windowA == windowId || conn.windowB == windowId else { return false }

            let otherId = conn.windowA == windowId ? conn.windowB : conn.windowA
            guard let other = trackedWindows[otherId] else { return true }

            let mf = window.frame
            let tf = other.frame

            // Check if still close enough on the snap axis
            switch (conn.windowA == windowId ? conn.sideA : conn.sideB,
                    conn.windowA == windowId ? conn.sideB : conn.sideA) {
            case (.right, .left):
                return abs(mf.maxX + snapGap - tf.minX) > detachThreshold
            case (.left, .right):
                return abs(mf.minX - snapGap - tf.maxX) > detachThreshold
            case (.bottom, .top):
                return abs(mf.minY - snapGap - tf.maxY) > detachThreshold
            case (.top, .bottom):
                return abs(mf.maxY + snapGap - tf.minY) > detachThreshold
            default:
                return true
            }
        }
    }

    // MARK: - Group Queries

    /// Find all windows connected to the given window (BFS through connections)
    func groupMembers(for window: NSWindow) -> [TimerWindow] {
        let startId = ObjectIdentifier(window)
        var visited = Set<ObjectIdentifier>()
        var queue = [startId]
        visited.insert(startId)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for conn in connections {
                let neighbor: ObjectIdentifier?
                if conn.windowA == current && !visited.contains(conn.windowB) {
                    neighbor = conn.windowB
                } else if conn.windowB == current && !visited.contains(conn.windowA) {
                    neighbor = conn.windowA
                } else {
                    neighbor = nil
                }
                if let n = neighbor {
                    visited.insert(n)
                    queue.append(n)
                }
            }
        }

        return visited.compactMap { trackedWindows[$0] }
    }

    var hasAnyConnections: Bool { !connections.isEmpty }
}
