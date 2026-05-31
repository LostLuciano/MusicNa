import UIKit

/// Circular progress ring for processing status
public class ProcessingRingView: UIView {
    
    private let backgroundCircle = CAShapeLayer()
    private let progressCircle = CAShapeLayer()
    private let percentageLabel = UILabel()
    
    public var progress: CGFloat = 0 {
        didSet {
            updateProgress()
        }
    }
    
    public var progressColor: UIColor = StudioColors.purpleAccent {
        didSet {
            progressCircle.strokeColor = progressColor.cgColor
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
        backgroundColor = .clear
        
        // Background circle
        backgroundCircle.fillColor = UIColor.clear.cgColor
        backgroundCircle.strokeColor = StudioColors.textTertiary.cgColor
        backgroundCircle.lineWidth = 8
        layer.addSublayer(backgroundCircle)
        
        // Progress circle
        progressCircle.fillColor = UIColor.clear.cgColor
        progressCircle.strokeColor = progressColor.cgColor
        progressCircle.lineWidth = 8
        progressCircle.lineCap = .round
        layer.addSublayer(progressCircle)
        
        // Percentage label
        percentageLabel.font = Typography.displayMedium
        percentageLabel.textColor = StudioColors.textPrimary
        percentageLabel.textAlignment = .center
        addSubview(percentageLabel)
        
        percentageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            percentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 8
        
        let circlePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: -CGFloat.pi / 2, endAngle: 3 * CGFloat.pi / 2, clockwise: true)
        
        backgroundCircle.path = circlePath.cgPath
        progressCircle.path = circlePath.cgPath
    }
    
    private func updateProgress() {
        let percentage = Int(progress * 100)
        percentageLabel.text = "\(percentage)%"
        
        // Update progress circle
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: min(bounds.width, bounds.height) / 2 - 8,
            startAngle: -CGFloat.pi / 2,
            endAngle: -CGFloat.pi / 2 + (2 * CGFloat.pi * progress),
            clockwise: true
        )
        
        progressCircle.path = circlePath.cgPath
    }
}
