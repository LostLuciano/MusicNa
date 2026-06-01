import UIKit

/// SnapKit module stub - provides basic constraint building
/// Uses native NSLayoutConstraint under the hood
/// Full SnapKit can be added later via SPM or CocoaPods

// MARK: - Public API

public struct SnapKit {}

public extension UIView {
    var snp: ConstraintBuilder {
        ConstraintBuilder(view: self)
    }
}

// MARK: - Constraint Builder

public struct ConstraintBuilder {
    fileprivate let view: UIView
    
    public func makeConstraints(_ closure: (ConstraintMaker) -> Void) {
        view.translatesAutoresizingMaskIntoConstraints = false
        let maker = ConstraintMaker(view: view)
        closure(maker)
    }
}

public class ConstraintMaker {
    fileprivate let view: UIView
    fileprivate var constraints: [NSLayoutConstraint] = []
    
    fileprivate init(view: UIView) {
        self.view = view
    }
    
    // MARK: - Edge Constraints
    
    @discardableResult
    public func edges(equalToSuperview: Void) -> Constraint {
        guard let superview = view.superview else { return Constraint() }
        return edges(equalTo: superview)
    }
    
    @discardableResult
    public func edges(equalTo view: UIView, insets: UIEdgeInsets = .zero) -> Constraint {
        self.constraints += [
            self.view.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            self.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            self.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            self.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right)
        ]
        NSLayoutConstraint.activate(self.constraints)
        return Constraint()
    }
    
    @discardableResult
    public func edges(equalTo view: UIView, offset: CGFloat) -> Constraint {
        return edges(equalTo: view, insets: UIEdgeInsets(top: offset, left: offset, bottom: offset, right: offset))
    }
    
    // MARK: - Width & Height
    
    @discardableResult
    public func width(equalToConstant: CGFloat) -> Constraint {
        constraints.append(view.widthAnchor.constraint(equalToConstant: equalToConstant))
        NSLayoutConstraint.activate(constraints)
        return Constraint()
    }
    
    @discardableResult
    public func height(equalToConstant: CGFloat) -> Constraint {
        constraints.append(view.heightAnchor.constraint(equalToConstant: equalToConstant))
        NSLayoutConstraint.activate(constraints)
        return Constraint()
    }
    
    // MARK: - Positional Constraints
    
    @discardableResult
    public func top(equalToSuperview: Void, offset: CGFloat = 0) -> Constraint {
        guard let superview = view.superview else { return Constraint() }
        return top(equalTo: superview.topAnchor, offset: offset)
    }
    
    @discardableResult
    public func top(equalTo anchor: NSLayoutYAxisAnchor, offset: CGFloat = 0) -> Constraint {
        constraints.append(view.topAnchor.constraint(equalTo: anchor, constant: offset))
        NSLayoutConstraint.activate(constraints)
        return Constraint()
    }
    
    @discardableResult
    public func left(equalToSuperview: Void, offset: CGFloat = 0) -> Constraint {
        guard let superview = view.superview else { return Constraint() }
        return left(equalTo: superview.leadingAnchor, offset: offset)
    }
    
    @discardableResult
    public func left(equalTo anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0) -> Constraint {
        constraints.append(view.leadingAnchor.constraint(equalTo: anchor, constant: offset))
        NSLayoutConstraint.activate(constraints)
        return Constraint()
    }
    
    @discardableResult
    public func right(equalToSuperview: Void, offset: CGFloat = 0) -> Constraint {
        guard let superview = view.superview else { return Constraint() }
        return right(equalTo: superview.trailingAnchor, offset: offset)
    }
    
    @discardableResult
    public func right(equalTo anchor: NSLayoutXAxisAnchor, offset: CGFloat = 0) -> Constraint {
        constraints.append(view.trailingAnchor.constraint(equalTo: anchor, constant: offset))
        NSLayoutConstraint.activate(constraints)
        return Constraint()
    }
}

public struct Constraint {}

