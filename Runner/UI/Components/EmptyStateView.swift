import UIKit

/// Empty state view for missing data
public class EmptyStateView: UIView {
    
    private let iconView = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    
    public var title: String = "" {
        didSet {
            titleLabel.text = title
        }
    }
    
    public var message: String = "" {
        didSet {
            messageLabel.text = message
        }
    }
    
    public var actionTitle: String? {
        didSet {
            if let actionTitle = actionTitle {
                actionButton.setTitle(actionTitle, for: .normal)
                actionButton.isHidden = false
            } else {
                actionButton.isHidden = true
            }
        }
    }
    
    public var actionHandler: (() -> Void)?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        // Icon view
        iconView.backgroundColor = StudioColors.glassDark
        iconView.layer.cornerRadius = 48
        iconView.clipsToBounds = true
        addSubview(iconView)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            iconView.widthAnchor.constraint(equalToConstant: 96),
            iconView.heightAnchor.constraint(equalToConstant: 96)
        ])
        
        // Icon image
        let iconLabel = UILabel()
        iconLabel.text = "🎵"
        iconLabel.font = UIFont.systemFont(ofSize: 48)
        iconLabel.textAlignment = .center
        iconView.addSubview(iconLabel)
        
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor)
        ])
        
        // Title label
        titleLabel.font = Typography.heading2
        titleLabel.textColor = StudioColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 24)
        ])
        
        // Message label
        messageLabel.font = Typography.bodyMedium
        messageLabel.textColor = StudioColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12)
        ])
        
        // Action button
        actionButton.setupPurpleStyle()
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionButton.isHidden = true
        addSubview(actionButton)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    @objc private func actionTapped() {
        actionHandler?()
    }
    
    /// Create empty state for missing data
    public static func createMissingData(title: String, message: String) -> EmptyStateView {
        let view = EmptyStateView()
        view.title = title
        view.message = message
        return view
    }
    
    /// Create empty state for no projects
    public static func createNoProjects() -> EmptyStateView {
        let view = EmptyStateView()
        view.title = "No Projects Yet"
        view.message = "Import or create an audio project to get started"
        view.actionTitle = "Import Audio"
        return view
    }
    
    /// Create empty state for no lyrics
    public static func createNoLyrics() -> EmptyStateView {
        let view = EmptyStateView()
        view.title = "No Lyrics Available"
        view.message = "Lyrics are not available for this track"
        return view
    }
    
    /// Create empty state for no analysis
    public static func createNoAnalysis() -> EmptyStateView {
        let view = EmptyStateView()
        view.title = "Not Analyzed Yet"
        view.message = "Run analysis to see chord and beat information"
        view.actionTitle = "Analyze"
        return view
    }
}
