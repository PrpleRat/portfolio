import Foundation

enum HandpanLayout {
    static let outerPositions = [2, 3, 4, 5, 6, 7, 8, 9]

    static func padId(for position: Int) -> String {
        "pos_\(position)"
    }

    static func angle(for position: Int) -> Double {
        switch position {
        case 2: .pi / 2
        case 3: 3 * .pi / 4
        case 4: .pi / 4
        case 5: .pi
        case 6: 0
        case 7: -3 * .pi / 4
        case 8: -.pi / 4
        case 9: -.pi / 2
        default: 0
        }
    }

    static func offset(for position: Int, radius: CGFloat) -> CGSize {
        let angle = angle(for: position)
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }

    static func offsetForCompactRing(index: Int, count: Int, radius: CGFloat) -> CGSize {
        guard count > 0 else { return .zero }
        let startAngle = Double.pi / 2
        let step = (2 * Double.pi) / Double(count)
        let angle = startAngle - Double(index) * step
        return CGSize(
            width: cos(angle) * radius,
            height: sin(angle) * radius
        )
    }

    static func layoutMetrics(outerCount: Int) -> (radiusFactor: CGFloat, padFactor: CGFloat) {
        switch outerCount {
        case ...4: (0.278, 0.258)
        case 5: (0.308, 0.242)
        case 6: (0.322, 0.232)
        case 7: (0.332, 0.226)
        default: (0.342, 0.222)
        }
    }
}
