import Foundation
import AsyncDisplayKit
import SwiftSignalKit
import Display

public let displayLinkDispatcher = DisplayLinkDispatcher()
private let dispatcher = displayLinkDispatcher

public enum ImageCorner: Equatable {
    case Corner(CGFloat)
    case Tail(CGFloat)
    
    public var extendedInsets: CGSize {
        switch self {
            case .Tail:
                return CGSize(width: 3.0, height: 0.0)
            default:
                return CGSize()
        }
    }
}

public func ==(lhs: ImageCorner, rhs: ImageCorner) -> Bool {
    switch lhs {
        case let .Corner(lhsRadius):
            switch rhs {
                case let .Corner(rhsRadius) where abs(lhsRadius - rhsRadius) < CGFloat(FLT_EPSILON):
                    return true
                default:
                    return false
            }
        case let .Tail(lhsRadius):
            switch rhs {
                case let .Tail(rhsRadius) where abs(lhsRadius - rhsRadius) < CGFloat(FLT_EPSILON):
                    return true
                default:
                    return false
            }
    }
}

public struct ImageCorners: Equatable {
    public let topLeft: ImageCorner
    public let topRight: ImageCorner
    public let bottomLeft: ImageCorner
    public let bottomRight: ImageCorner
    
    public init(radius: CGFloat) {
        self.topLeft = .Corner(radius)
        self.topRight = .Corner(radius)
        self.bottomLeft = .Corner(radius)
        self.bottomRight = .Corner(radius)
    }
    
    public init(topLeft: ImageCorner, topRight: ImageCorner, bottomLeft: ImageCorner, bottomRight: ImageCorner) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomLeft = bottomLeft
        self.bottomRight = bottomRight
    }
    
    public init() {
        self.init(topLeft: .Corner(0.0), topRight: .Corner(0.0), bottomLeft: .Corner(0.0), bottomRight: .Corner(0.0))
    }
    
    public var extendedEdges: UIEdgeInsets {
        let left = self.bottomLeft.extendedInsets.width
        let right = self.bottomRight.extendedInsets.width
        
        return UIEdgeInsets(top: 0.0, left: left, bottom: 0.0, right: right)
    }
}

public func ==(lhs: ImageCorners, rhs: ImageCorners) -> Bool {
    return lhs.topLeft == rhs.topLeft && lhs.topRight == rhs.topRight && lhs.bottomLeft == rhs.bottomLeft && lhs.bottomRight == rhs.bottomRight
}

public class ImageNode: ASDisplayNode {
    private var disposable = MetaDisposable()
    
    override init() {
        super.init()
    }
    
    public func setSignal(_ signal: Signal<UIImage, NoError>) {
        var first = true
        self.disposable.set((signal |> deliverOnMainQueue).start(next: {[weak self] next in
            dispatcher.dispatch {
                if let strongSelf = self {
                    strongSelf.contents = next.cgImage
                    if first {
                        first = false
                        if strongSelf.isNodeLoaded {
                            strongSelf.layer.animateAlpha(from: 0.0, to: 1.0, duration: 0.18)
                        }
                    }
                }
            }
        }))
    }
    
    public override func clearContents() {
        super.clearContents()
        
        self.contents = nil
        self.disposable.set(nil)
    }
}
