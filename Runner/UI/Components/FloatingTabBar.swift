import UIKit

/// Floating tab bar at bottom of screen with glass effect
public class FloatingTabBar: UIView {
    
    public weak var delegate: FloatingTabBarDelegate?
    
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0
    
    public var items: [FloatingTabBarItem] = [] {
        didSet {
            setupButtons()
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Background
        GlassEffect.configureGlassCard(self, cornerRadius: 24)
        
        // Stack view
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.spacing = 8
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    private func setupButtons() {
        // Remove existing buttons
        buttons.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        
        // Create new buttons
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.tag = index
            button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
            
            // Configure button
            var config = UIButton.Configuration.plain()
            config.image = item.icon?.withRenderingMode(.alwaysTemplate)
            config.imagePadding = 8
            config.baseForegroundColor = index == selectedIndex ? StudioColors.purpleAccent : StudioColors.textSecondary
            button.configuration = config
            
            // Add to stack
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }
    }
    
    @objc private func tabTapped(_ sender: UIButton) {
        let previousIndex = selectedIndex
        selectedIndex = sender.tag
        
        // Update button colors
        buttons[previousIndex].configuration?.baseForegroundColor = StudioColors.textSecondary
        buttons[selectedIndex].configuration?.baseForegroundColor = StudioColors.purpleAccent
        
        // Notify delegate
        delegate?.floatingTabBar(self, didSelectItemAt: selectedIndex)
    }
    
    public func selectItem(at index: Int) {
        guard index < buttons.count else { return }
        buttons[index].sendActions(for: .touchUpInside)
    }
}

// MARK: - Data Model

public struct FloatingTabBarItem {
    public let icon: UIImage?
    public let title: String
    
    public init(icon: UIImage?, title: String) {
        self.icon = icon
        self.title = title
    }
}

// MARK: - Delegate

public protocol FloatingTabBarDelegate: AnyObject {
    func floatingTabBar(_ tabBar: FloatingTabBar, didSelectItemAt index: Int)
}
