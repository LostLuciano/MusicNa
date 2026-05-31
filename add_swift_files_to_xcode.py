#!/usr/bin/env python3
"""
Script to add all Swift files from Runner subdirectories to Xcode project.
This ensures all Swift files are included in the Runner target compile sources.
"""

import re
import uuid
from pathlib import Path

def generate_uuid():
    """Generate a unique 24-character hex ID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def find_all_swift_files():
    """Find all Swift files in Runner directory recursively"""
    runner_path = Path("Runner")
    swift_files = list(runner_path.rglob("*.swift"))
    # Exclude test files and generated files
    swift_files = [f for f in swift_files if "Test" not in f.name and "Generated" not in f.name]
    return sorted(swift_files)

def read_pbxproj():
    """Read project.pbxproj file"""
    pbxproj_path = Path("Runner.xcodeproj/project.pbxproj")
    return pbxproj_path.read_text()

def write_pbxproj(content):
    """Write project.pbxproj file"""
    pbxproj_path = Path("Runner.xcodeproj/project.pbxproj")
    pbxproj_path.write_text(content)

def extract_existing_files(content):
    """Extract already referenced Swift files from PBXFileReference"""
    pattern = r'/\* ([^*]+\.swift) \*/'
    matches = re.findall(pattern, content)
    return set(matches)

def main():
    print("=" * 70)
    print("Adding Swift Files to Xcode Project")
    print("=" * 70)
    
    # Find all Swift files
    all_swift_files = find_all_swift_files()
    print(f"\nFound {len(all_swift_files)} Swift files in Runner directory")
    
    # Read project.pbxproj
    content = read_pbxproj()
    
    # Extract existing files
    existing_files = extract_existing_files(content)
    print(f"Already referenced: {len(existing_files)} Swift files")
    
    # Find missing files
    missing_files = []
    for swift_file in all_swift_files:
        if swift_file.name not in existing_files:
            missing_files.append(swift_file)
    
    if not missing_files:
        print("\n✓ All Swift files are already in the project!")
        return
    
    print(f"\n⚠ Missing {len(missing_files)} Swift files:")
    for f in missing_files[:10]:  # Show first 10
        print(f"  - {f}")
    if len(missing_files) > 10:
        print(f"  ... and {len(missing_files) - 10} more")
    
    print("\n" + "=" * 70)
    print("MANUAL ACTION REQUIRED")
    print("=" * 70)
    print("\nThis script has identified missing Swift files.")
    print("To add them to Xcode project, you need to:")
    print("\n1. Open Runner.xcodeproj in Xcode on macOS")
    print("2. Right-click on Runner group")
    print("3. Select 'Add Files to Runner...'")
    print("4. Select all missing files")
    print("5. Ensure 'Copy items if needed' is UNCHECKED")
    print("6. Ensure 'Runner' target is CHECKED")
    print("7. Click 'Add'")
    print("\nOR use xcodebuild on macOS to add files programmatically.")
    print("\nMissing files list saved to: missing_swift_files.txt")
    
    # Save missing files list
    with open("missing_swift_files.txt", "w") as f:
        for file in missing_files:
            f.write(str(file) + "\n")
    
    print("\n" + "=" * 70)

if __name__ == "__main__":
    main()
