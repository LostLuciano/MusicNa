import UIKit

/// Delegate protocol for ChordTimelineView to notify parent controller of interactions
public protocol ChordTimelineDelegate: AnyObject {
    /// Called when user selects a chord at specific time
    func chordTimeline(_ timeline: ChordTimelineView, didSelectChordAt time: TimeInterval)
}
