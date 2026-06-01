import UIKit

/// Delegate protocol for StemChannelView to notify parent controller of stem mixing changes
public protocol StemChannelDelegate: AnyObject {
    /// Called when stem volume is changed
    func stemChannel(_ view: UIView, didChangeVolume volume: Float, for stem: String)
    
    /// Called when stem is muted/unmuted
    func stemChannel(_ view: UIView, didSetMuted isMuted: Bool, for stem: String)
    
    /// Called when stem is soloed/unsoloed
    func stemChannel(_ view: UIView, didSetSolo isSolo: Bool, for stem: String)
}
