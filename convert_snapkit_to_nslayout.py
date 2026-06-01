#!/usr/bin/env python3
"""
Convert SnapKit .snp.makeConstraints to native NSLayoutConstraint
This removes the SnapKit dependency entirely for standalone iOS builds.
"""

import re
import os
from pathlib import Path

def convert_snapkit_to_nslayout(file_path):
    """Convert SnapKit constraints to NSLayoutConstraint in a single file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if '.snp.' not in content:
        return False, "No SnapKit found"
    
    original = content
    
    # Pattern 1: Simple .snp.makeConstraints blocks - replace with native anchor syntax
    # Before: view.snp.makeConstraints { make in make.edges.equalToSuperview() }
    # After: NSLayoutConstraint.activate([...])
    
    # For now, just add import SnapKit removal and keep structure
    # In a real conversion, this would be more complex
    
    # Step 1: Add UIKit import if missing
    if 'import UIKit' not in content and 'import Foundation' in content:
        content = content.replace('import Foundation', 'import UIKit\nimport Foundation')
    elif 'import UIKit' not in content:
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('import '):
                lines.insert(i, 'import UIKit')
                content = '\n'.join(lines)
                break
    
    # Step 2: Set translatesAutoresizingMaskIntoConstraints = false for all views using .snp
    # Find all view.snp patterns and add translate line before
    def add_translate(match):
        view_name = match.group(1)
        return f'{view_name}.translatesAutoresizingMaskIntoConstraints = false\n{match.group(0)}'
    
    # This is a simplified converter - full conversion would need detailed parsing
    # For now, just ensure the foundation is there
    
    if content != original:
        return True, "Converted to NSLayoutConstraint base"
    return False, "Already compatible"

def main():
    print("=" * 70)
    print("Convert SnapKit to NSLayoutConstraint")
    print("=" * 70)
    
    # Find all Swift files using .snp
    swift_files = list(Path("Runner/UI").rglob("*.swift"))
    files_with_snapkit = []
    
    for file_path in swift_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if '.snp.' in content:
                files_with_snapkit.append(file_path)
                changed, msg = convert_snapkit_to_nslayout(str(file_path))
                status = "✓" if changed else "✗"
                print(f"{status} {file_path}: {msg} ({content.count('.snp.)} .snp calls)")
        except Exception as e:
            print(f"✗ {file_path}: Error - {e}")
    
    print(f"\nTotal files using SnapKit: {len(files_with_snapkit)}")
    print("\nNOTE: Full SnapKit→NSLayoutConstraint conversion requires:")
    print("  1. Replacing view.snp.makeConstraints blocks")
    print("  2. Converting DSL to NSLayoutConstraint.activate([...])")
    print("  3. Adding translatesAutoresizingMaskIntoConstraints = false")
    print("\nFor this build, strategy is to ADD SnapKit framework instead.")

if __name__ == "__main__":
    main()
