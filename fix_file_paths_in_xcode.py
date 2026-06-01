#!/usr/bin/env python3
"""
Script to fix file paths in Xcode project.pbxproj file.
The issue is that file references are missing the 'Runner/' prefix.
"""

import re
from pathlib import Path

def read_pbxproj():
    """Read project.pbxproj file"""
    pbxproj_path = Path("Runner.xcodeproj/project.pbxproj")
    return pbxproj_path.read_text()

def write_pbxproj(content):
    """Write project.pbxproj file"""
    pbxproj_path = Path("Runner.xcodeproj/project.pbxproj")
    pbxproj_path.write_text(content)

def fix_file_paths(content):
    """Fix file paths by adding Runner/ prefix where needed"""
    
    # List of paths that need the Runner/ prefix
    paths_to_fix = [
        'AI/ChordTheory.swift',
        'AI/CoreMLStemSeparatorWrapper.swift',
        'AI/DemoDataManager.swift',
        'AI/ModelManager.swift',
        'Data/ProjectStore.swift',
        'Data/StemProject.swift',
        'Data/TrackMetadata.swift',
        'System/CacheManager.swift',
        'System/ExportManager.swift',
        'System/FileImportManager.swift',
        'System/Logger.swift',
        'System/PerformanceGuard.swift',
        'System/ProcessingGate.swift',
        'UI/Components/AudioLevelMeterView.swift',
        'UI/Components/BeatGridView.swift',
        'UI/Components/ChordPatternView.swift',
        'UI/Components/ChordTimelineView.swift',
        'UI/Components/EmptyStateView.swift',
        'UI/Components/FloatingActionButton.swift',
        'UI/Components/FloatingTabBar.swift',
        'UI/Components/GlassCardView.swift',
        'UI/Components/LiquidBackgroundView.swift',
        'UI/Components/LyricsKaraokeView.swift',
        'UI/Components/ProcessingRingView.swift',
        'UI/Components/ProcessingStageRowView.swift',
        'UI/Components/PurpleGlowButton.swift',
        'UI/Components/StemChannelView.swift',
        'UI/Components/StudioSegmentedControl.swift',
        'UI/Components/WaveformView.swift',
        'UI/Screens/AnalyzerViewController.swift',
        'UI/Screens/ExportViewController.swift',
        'UI/Screens/HomeViewController.swift',
        'UI/Screens/ImportSourceViewController.swift',
        'UI/Screens/LibraryViewController.swift',
        'UI/Screens/MixerViewController.swift',
        'UI/Screens/ProcessingViewController.swift',
        'UI/Screens/ProfileViewController.swift',
        'UI/Screens/RecordingViewController.swift',
        'UI/Screens/ResultViewController.swift',
        'UI/Screens/StudioSettingsViewController.swift',
        'UI/Screens/StudioTabBarController.swift',
        'UI/Theme/GlassEffect.swift',
        'UI/Theme/StudioColors.swift',
        'UI/Theme/StudioTheme.swift',
        'UI/Theme/Typography.swift',
    ]
    
    fixed_count = 0
    for path in paths_to_fix:
        # Pattern to match: path = AI/ChordTheory.swift; sourceTree = "<group>";
        # We need to replace with: path = Runner/AI/ChordTheory.swift; sourceTree = "<group>";
        pattern = f'path = {path}; sourceTree = "<group>";'
        replacement = f'path = Runner/{path}; sourceTree = "<group>";'
        
        if pattern in content:
            content = content.replace(pattern, replacement)
            fixed_count += 1
            print(f"✓ Fixed: {path}")
    
    return content, fixed_count

def main():
    print("=" * 70)
    print("Fixing File Paths in Xcode Project")
    print("=" * 70)
    
    # Read project.pbxproj
    print("\nReading project.pbxproj...")
    content = read_pbxproj()
    
    # Fix file paths
    print("\nFixing file paths...")
    fixed_content, fixed_count = fix_file_paths(content)
    
    if fixed_count == 0:
        print("\n⚠ No paths were fixed. They may already be correct.")
        return
    
    # Write back
    print(f"\nWriting changes back to project.pbxproj...")
    write_pbxproj(fixed_content)
    
    print(f"\n✓ Successfully fixed {fixed_count} file paths!")
    print("\n" + "=" * 70)
    print("NEXT STEPS")
    print("=" * 70)
    print("\n1. Commit the changes to project.pbxproj")
    print("2. Push to GitHub")
    print("3. The GitHub Actions workflow should now build successfully")
    print("\n" + "=" * 70)

if __name__ == "__main__":
    main()
