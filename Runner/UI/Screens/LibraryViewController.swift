import UIKit

/// Library screen - list all projects with filtering
public class LibraryViewController: UIViewController {
    
    private let tableView = UITableView()
    private let filterControl = StudioSegmentedControl(items: ["Semua", "Lagu", "Sesi", "Impor"])
    private let emptyStateView = EmptyStateView()
    
    private let projectStore = ProjectStore.shared
    private var projects: [StemProject] = []
    private var filteredProjects: [StemProject] = []
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadProjects()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadProjects()
    }
    
    private func setupUI() {
        setupStudioTheme()
        setupNavigationBar(title: "Studio Library", subtitle: "Semua Proyek")
        
        // Filter control
        filterControl.selectedSegmentIndex = 0
        filterControl.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        view.addSubview(filterControl)
        
        filterControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            filterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            filterControl.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProjectTableCell.self, forCellReuseIdentifier: "ProjectCell")
        view.addSubview(tableView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: filterControl.bottomAnchor, constant: 16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Empty state
        emptyStateView.title = "Tidak Ada Proyek"
        emptyStateView.message = "Impor atau buat proyek audio untuk memulai"
        emptyStateView.actionTitle = "Impor Audio"
        emptyStateView.actionHandler = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        view.addSubview(emptyStateView)
        
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.topAnchor.constraint(equalTo: filterControl.bottomAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadProjects() {
        do {
            projects = try projectStore.loadAllProjects()
            applyFilter()
            tableView.reloadData()
            updateEmptyState()
        } catch {
            Logger.shared.error("Failed to load projects: \(error.localizedDescription)")
        }
    }
    
    @objc private func filterChanged(_ sender: UISegmentedControl) {
        applyFilter()
        tableView.reloadData()
    }
    
    private func applyFilter() {
        let filterIndex = filterControl.selectedSegmentIndex
        
        filteredProjects = projects.filter { project in
            switch filterIndex {
            case 0: // Semua
                return true
            case 1: // Lagu
                return project.genre != nil
            case 2: // Sesi
                return project.genre == nil
            case 3: // Impor
                return project.originalAudioURL != nil
            default:
                return true
            }
        }
    }
    
    private func updateEmptyState() {
        emptyStateView.isHidden = !filteredProjects.isEmpty
    }
}

// MARK: - UITableViewDataSource

extension LibraryViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProjects.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! ProjectTableCell
        let project = filteredProjects[indexPath.row]
        cell.configure(with: project)
        cell.playHandler = { [weak self] in
            self?.playProject(project)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LibraryViewController: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let project = filteredProjects[indexPath.row]
        
        // Navigate based on project status
        if !project.stemURLs.isEmpty {
            // Already separated - open mixer or result
            let vc = ResultViewController()
            vc.project = project
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // Not separated - open processing
            let vc = ProcessingViewController()
            vc.project = project
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    private func playProject(_ project: StemProject) {
        guard let audioURL = project.originalAudioURL else { return }
        
        do {
            let audioEngine = AudioEngineManager()
            try audioEngine.play()
            Logger.shared.info("Playing project: \(project.name)")
        } catch {
            Logger.shared.error("Failed to play: \(error.localizedDescription)")
        }
    }
}

// MARK: - Project Table Cell

private class ProjectTableCell: UITableViewCell {
    
    private let cardView = GlassCardView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let statusLabel = UILabel()
    private let playButton = UIButton(type: .system)
    
    public var playHandler: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Card
        cardView.setupGlassCard()
        contentView.addSubview(cardView)
        
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        // Title
        titleLabel.font = Typography.labelLarge
        titleLabel.textColor = StudioColors.textPrimary
        cardView.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12)
        ])
        
        // Info
        infoLabel.font = Typography.captionSmall
        infoLabel.textColor = StudioColors.textSecondary
        cardView.addSubview(infoLabel)
        
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            infoLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        ])
        
        // Status
        statusLabel.font = Typography.labelSmall
        statusLabel.textColor = StudioColors.statusSuccess
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 6
        statusLabel.clipsToBounds = true
        statusLabel.backgroundColor = StudioColors.glassDark
        cardView.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            statusLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            statusLabel.widthAnchor.constraint(equalToConstant: 80),
            statusLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Play button
        playButton.setImage(UIImage(systemName: "play.circle.fill"), for: .normal)
        playButton.tintColor = StudioColors.purpleAccent
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        cardView.addSubview(playButton)
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            playButton.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    public func configure(with project: StemProject) {
        titleLabel.text = project.name
        
        let duration = String(format: "%.1f", project.duration / 60)
        let bpm = project.bpm > 0 ? String(format: "%.0f BPM", project.bpm) : "Unknown BPM"
        infoLabel.text = "\(duration) min · \(bpm)"
        
        let status = project.stemURLs.isEmpty ? "Pending" : "Separated"
        statusLabel.text = status
        statusLabel.textColor = project.stemURLs.isEmpty ? StudioColors.statusWarning : StudioColors.statusSuccess
    }
    
    @objc private func playTapped() {
        playHandler?()
    }
}
