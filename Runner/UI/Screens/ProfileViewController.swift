import UIKit

/// Profile screen - user info and menu
public class ProfileViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let userNameLabel = UILabel()
    private let statsStackView = UIStackView()
    private let menuStackView = UIStackView()
    
    private let projectStore = ProjectStore.shared
    private let cacheManager = CacheManager.shared
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateStats()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateStats()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Profile", subtitle: "User Settings")
        
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Content view
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // User name
        userNameLabel.text = "Musisi Baru"
        userNameLabel.font = Typography.heading1
        userNameLabel.textColor = StudioColors.textPrimary
        contentView.addSubview(userNameLabel)
        
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            userNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            userNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16)
        ])
        
        // Stats
        setupStats()
        
        // Menu
        setupMenu()
    }
    
    private func setupStats() {
        let statsLabel = UILabel()
        statsLabel.text = "STATISTICS"
        statsLabel.font = Typography.labelSmall
        statsLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(statsLabel)
        
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 24)
        ])
        
        // Stats stack
        statsStackView.axis = .vertical
        statsStackView.spacing = 12
        contentView.addSubview(statsStackView)
        
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            statsStackView.topAnchor.constraint(equalTo: statsLabel.bottomAnchor, constant: 12)
        ])
    }
    
    private func setupMenu() {
        let menuLabel = UILabel()
        menuLabel.text = "MENU"
        menuLabel.font = Typography.labelSmall
        menuLabel.textColor = StudioColors.textTertiary
        contentView.addSubview(menuLabel)
        
        menuLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            menuLabel.topAnchor.constraint(equalTo: statsStackView.bottomAnchor, constant: 24)
        ])
        
        // Menu stack
        menuStackView.axis = .vertical
        menuStackView.spacing = 8
        contentView.addSubview(menuStackView)
        
        menuStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            menuStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            menuStackView.topAnchor.constraint(equalTo: menuLabel.bottomAnchor, constant: 12),
            menuStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        let menuItems = [
            ("Analisis Proyek", #selector(analyzeProjectsTapped)),
            ("Rekaman Tersimpan", #selector(savedRecordingsTapped)),
            ("Pengaturan Studio", #selector(settingsTapped)),
            ("Tentang Aplikasi", #selector(aboutTapped))
        ]
        
        for (title, action) in menuItems {
            let button = createMenuButton(title: title, action: action)
            menuStackView.addArrangedSubview(button)
        }
    }
    
    private func createMenuButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.addTarget(self, action: action, for: .touchUpInside)
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.right")
        config.imagePadding = 12
        config.title = title
        config.baseForegroundColor = StudioColors.textPrimary
        config.titleAlignment = .leading
        
        button.configuration = config
        button.backgroundColor = StudioColors.glassDark
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        return button
    }
    
    private func updateStats() {
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        do {
            let projects = try projectStore.loadAllProjects()
            let stats = cacheManager.getCacheStatistics()
            
            let projectCount = projects.count
            let recordingCount = projects.filter { $0.stemURLs.isEmpty }.count
            let cacheSize = stats.totalSize
            
            let projectLabel = createStatLabel(title: "Projects", value: "\(projectCount)")
            let recordingLabel = createStatLabel(title: "Recordings", value: "\(recordingCount)")
            let cacheLabel = createStatLabel(title: "Cache Size", value: formatBytes(cacheSize))
            
            statsStackView.addArrangedSubview(projectLabel)
            statsStackView.addArrangedSubview(recordingLabel)
            statsStackView.addArrangedSubview(cacheLabel)
        } catch {
            Logger.shared.error("Failed to load stats: \(error.localizedDescription)")
        }
    }
    
    private func createStatLabel(title: String, value: String) -> UIView {
        let container = UIView()
        container.backgroundColor = StudioColors.glassDark
        container.layer.cornerRadius = 12
        container.clipsToBounds = true
        container.heightAnchor.constraint(equalToConstant: 48).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = Typography.labelMedium
        titleLabel.textColor = StudioColors.textSecondary
        container.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = Typography.labelLarge
        valueLabel.textColor = StudioColors.purpleAccent
        valueLabel.textAlignment = .right
        container.addSubview(valueLabel)
        
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    @objc private func analyzeProjectsTapped() {
        Logger.shared.info("Analyze projects tapped")
    }
    
    @objc private func savedRecordingsTapped() {
        Logger.shared.info("Saved recordings tapped")
    }
    
    @objc private func settingsTapped() {
        let vc = StudioSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func aboutTapped() {
        let alert = UIAlertController(title: "About", message: "NativeMusicX v1.0\nAI-Powered Stem Separation", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
