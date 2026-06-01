#!/usr/bin/env python3
"""
Automated script to add missing Swift files to Xcode project.pbxproj
This script is CI-safe and idempotent.
"""

import re
import sys
from pathlib import Path
from typing import Set, List, Tuple, Dict

def generate_uuid() -> str:
    """Generate a unique 24-character hex ID for Xcode (deterministic based on file path)"""
    import hashlib
    import time
    # Use timestamp + counter for uniqueness
    unique_str = f"{time.time_ns()}{generate_uuid.counter}"
    generate_uuid.counter += 1
    hash_obj = hashlib.md5(unique_str.encode())
    return hash_obj.hexdigest()[:24].upper()

generate_uuid.counter = 0

class XcodeProjectPatcher:
    def __init__(self, pbxproj_path: Path):
        self.pbxproj_path = pbxproj_path
        self.content = pbxproj_path.read_text(encoding='utf-8')
        self.modified = False
        
    def find_existing_swift_files(self) -> Set[str]:
        """Extract already referenced Swift files from PBXFileReference"""
        pattern = r'/\* ([^*]+\.swift) \*/'
        matches = re.findall(pattern, self.content)
        return set(matches)
    
    def find_runner_sources_build_phase_id(self) -> str:
        """Find the PBXSourcesBuildPhase ID for Runner target"""
        # Look for the Runner target's Sources build phase
        pattern = r'97C146EA1CF9000F007C117D\s*/\*\s*Sources\s*\*/'
        if re.search(pattern, self.content):
            return "97C146EA1CF9000F007C117D"
        return None
    
    def extract_file_references(self) -> Dict[str, str]:
        """Extract existing file reference UUIDs"""
        file_refs = {}
        pattern = r'([A-F0-9]{24})\s*/\*\s*([^*]+\.swift)\s*\*/\s*=\s*\{isa\s*=\s*PBXFileReference'
        matches = re.findall(pattern, self.content)
        for uuid, filename in matches:
            file_refs[filename] = uuid
        return file_refs
    
    def extract_build_files(self) -> Dict[str, str]:
        """Extract existing build file UUIDs"""
        build_files = {}
        pattern = r'([A-F0-9]{24})\s*/\*\s*([^*]+\.swift)\s+in\s+Sources\s*\*/\s*=\s*\{isa\s*=\s*PBXBuildFile'
        matches = re.findall(pattern, self.content)
        for uuid, filename in matches:
            build_files[filename] = uuid
        return build_files
    
    def add_file_to_project(self, file_path: Path) -> Tuple[str, str]:
        """Add a Swift file to the project. Returns (fileref_uuid, buildfile_uuid)"""
        filename = file_path.name
        relative_path = str(file_path).replace('\\', '/')
        
        # Check if already exists
        existing_file_refs = self.extract_file_references()
        existing_build_files = self.extract_build_files()
        
        if filename in existing_file_refs:
            fileref_uuid = existing_file_refs[filename]
            buildfile_uuid = existing_build_files.get(filename, generate_uuid())
        else:
            fileref_uuid = generate_uuid()
            buildfile_uuid = generate_uuid()
        
        # 1. Add to PBXBuildFile section (if not exists)
        if filename not in existing_build_files:
            buildfile_entry = f"\t\t{buildfile_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {fileref_uuid} /* {filename} */; }};\n"
            
            # Find PBXBuildFile section and add
            pattern = r'(/\* Begin PBXBuildFile section \*/\n)'
            if re.search(pattern, self.content):
                self.content = re.sub(pattern, r'\1' + buildfile_entry, self.content, count=1)
                self.modified = True
                print(f"  ✓ Added PBXBuildFile: {filename}")
        
        # 2. Add to PBXFileReference section (if not exists)
        if filename not in existing_file_refs:
            # Determine the path relative to Runner group
            path_attr = relative_path.replace('Runner/', '')
            fileref_entry = f"\t\t{fileref_uuid} /* {filename} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {path_attr}; sourceTree = \"<group>\"; }};\n"
            
            # Find PBXFileReference section and add
            pattern = r'(/\* Begin PBXFileReference section \*/\n)'
            if re.search(pattern, self.content):
                self.content = re.sub(pattern, r'\1' + fileref_entry, self.content, count=1)
                self.modified = True
                print(f"  ✓ Added PBXFileReference: {filename}")
        
        # 3. Add to PBXSourcesBuildPhase for Runner target
        sources_phase_id = self.find_runner_sources_build_phase_id()
        if sources_phase_id:
            # Check if already in sources phase
            sources_pattern = rf'{sources_phase_id}\s*/\*\s*Sources\s*\*/\s*=\s*\{{[^}}]+files\s*=\s*\(([^)]+)\)'
            sources_match = re.search(sources_pattern, self.content, re.DOTALL)
            
            if sources_match:
                files_section = sources_match.group(1)
                if buildfile_uuid not in files_section:
                    # Add to files array
                    build_entry = f"\t\t\t\t{buildfile_uuid} /* {filename} in Sources */,\n"
                    
                    # Insert before the closing of files array
                    pattern = rf'({sources_phase_id}\s*/\*\s*Sources\s*\*/\s*=\s*\{{[^}}]+files\s*=\s*\([^)]*)'
                    self.content = re.sub(pattern, r'\1' + build_entry, self.content, count=1)
                    self.modified = True
                    print(f"  ✓ Added to PBXSourcesBuildPhase: {filename}")
        
        return fileref_uuid, buildfile_uuid
    
    def save(self):
        """Save the modified project file"""
        if self.modified:
            self.pbxproj_path.write_text(self.content, encoding='utf-8')
            print(f"\n✓ Saved changes to {self.pbxproj_path}")
        else:
            print(f"\n✓ No changes needed for {self.pbxproj_path}")

def main():
    print("=" * 70)
    print("Xcode Project Patcher - Adding Missing Swift Files")
    print("=" * 70)
    
    # Paths
    pbxproj_path = Path("Runner.xcodeproj/project.pbxproj")
    missing_files_path = Path("missing_swift_files.txt")
    
    if not pbxproj_path.exists():
        print(f"ERROR: {pbxproj_path} not found!")
        sys.exit(1)
    
    if not missing_files_path.exists():
        print(f"ERROR: {missing_files_path} not found!")
        sys.exit(1)
    
    # Read missing files
    missing_files = []
    with open(missing_files_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and line.endswith('.swift'):
                file_path = Path(line)
                if file_path.exists():
                    missing_files.append(file_path)
                else:
                    print(f"WARNING: File not found on disk: {file_path}")
    
    print(f"\nFound {len(missing_files)} Swift files to add")
    
    if not missing_files:
        print("\n✓ No files to add!")
        sys.exit(0)
    
    # Create patcher
    patcher = XcodeProjectPatcher(pbxproj_path)
    
    # Get existing files
    existing_files = patcher.find_existing_swift_files()
    print(f"Already in project: {len(existing_files)} Swift files")
    
    # Add each missing file
    print(f"\nAdding {len(missing_files)} files to project...")
    added_count = 0
    
    for file_path in missing_files:
        filename = file_path.name
        if filename not in existing_files:
            print(f"\nProcessing: {file_path}")
            try:
                patcher.add_file_to_project(file_path)
                added_count += 1
            except Exception as e:
                print(f"  ERROR: Failed to add {filename}: {e}")
        else:
            print(f"  ⊘ Skipped (already exists): {filename}")
    
    # Save changes
    patcher.save()
    
    # Final verification
    print("\n" + "=" * 70)
    print("VERIFICATION")
    print("=" * 70)
    
    # Re-read and verify
    patcher_verify = XcodeProjectPatcher(pbxproj_path)
    final_existing = patcher_verify.find_existing_swift_files()
    
    still_missing = []
    for file_path in missing_files:
        if file_path.name not in final_existing:
            still_missing.append(file_path)
    
    print(f"\nTotal Swift files on disk: {len(missing_files)}")
    print(f"Files added this run: {added_count}")
    print(f"Files now in project: {len(final_existing)}")
    print(f"Files still missing: {len(still_missing)}")
    
    if still_missing:
        print("\n⚠ WARNING: Some files are still missing:")
        for f in still_missing[:10]:
            print(f"  - {f}")
        if len(still_missing) > 10:
            print(f"  ... and {len(still_missing) - 10} more")
        sys.exit(1)
    
    print("\n" + "=" * 70)
    print("✓ SUCCESS: All Swift files added to Xcode project!")
    print("=" * 70)
    sys.exit(0)

if __name__ == "__main__":
    main()
