import UIKit

/// Main tab bar controller coordinating all 10 screens with floating tab bar
public class StudioTabBarController: UITabBarController {
    
    private let floatingTabBar = FloatingTabBar()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabs()
        setupTheme()
    }
    
    private func setupUI() {
        // Hide standard tab bar
        tabBar.isHidden = true
        
        // Add floating tab bar
        view.addSubview(floatingTabBar)
        floatingTabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            floatingTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            floatingTabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            floatingTabBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Set delegate for tab selection
        floatingTabBar.delegate = self
    }
    
    private func setupTabs() {
        let tabs: [(icon: UIImage?, title: String, vc: UIViewController)] = [
            (UIImage(systemName: "house.fill"), "Home", createNavController(HomeViewController())),
            (UIImage(systemName: "books.vertical.fill"), "Library", createNavController(LibraryViewController())),
            (UIImage(systemName: "waveform.circle.fill"), "Mixer", createNavController(MixerViewController())),
            (UIImage(systemName: "waveform.path.ecg"), "Analyzer", createNavController(AnalyzerViewController())),
            (UIImage(systemName: "person.fill"), "Profile", createNavController(ProfileViewController()))
        ]
        
        viewControllers = tabs.map { $0.vc }
        
        // Configure floating tab bar with FloatingTabBarItem
        let items = tabs.map { FloatingTabBarItem(icon: $0.icon, title: $0.title) }
        floatingTabBar.items = items
        
        selectedIndex = 0
    }
    
    private func setupTheme() {
        StudioTheme.shared.setupAppearance()
        view.backgroundColor = StudioColors.backgroundDark
        GlassEffect.applyGradientBackground(to: view)
    }
    
    private func createNavController(_ rootVC: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootVC)
        navController.navigationBar.prefersLargeTitles = false
        return navController
    }
}

// MARK: - FloatingTabBar Delegate

extension StudioTabBarController: FloatingTabBarDelegate {
    public func floatingTabBar(_ tabBar: FloatingTabBar, didSelectItemAt index: Int) {
        selectedIndex = index
    }
}
