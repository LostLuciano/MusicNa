import UIKit

/// Styled segmented control with glass effect
public class StudioSegmentedControl: UISegmentedControl {
    
    public override init(items: [Any]?) {
        super.init(items: items)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Appearance
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.labelMedium,
            .foregroundColor: StudioColors.textSecondary
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.labelMedium,
            .foregroundColor: UIColor.white
        ]
        
        setTitleTextAttributes(normalAttributes, for: .normal)
        setTitleTextAttributes(selectedAttributes, for: .selected)
        
        // Colors
        selectedSegmentTintColor = StudioColors.purpleAccent
        backgroundColor = StudioColors.glassDark
        
        // Border
        layer.borderColor = StudioColors.glassBorder.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 12
        clipsToBounds = true
    }
}
