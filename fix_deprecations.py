#!/usr/bin/env python3
"""
Script to fix withOpacity deprecation warnings in Flutter project.
Replaces withOpacity(value) with withValues(alpha: value)
"""

import os
import re
import glob

def fix_with_opacity_in_file(file_path):
    """Fix withOpacity deprecations in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # Pattern to match .withOpacity(number)
        pattern = r'\.withOpacity\(([0-9]*\.?[0-9]+)\)'
        replacement = r'.withValues(alpha: \1)'
        
        new_content = re.sub(pattern, replacement, content)
        
        if new_content != content:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.write(new_content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process all Dart files."""
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(script_dir, "lib")
    
    dart_files = glob.glob(f"{lib_dir}/**/*.dart", recursive=True)
    
    fixed_files = []
    
    for dart_file in dart_files:
        if fix_with_opacity_in_file(dart_file):
            fixed_files.append(dart_file)
            print(f"Fixed: {os.path.relpath(dart_file, script_dir)}")
    
    print(f"\nTotal files fixed: {len(fixed_files)}")
    if len(fixed_files) > 0:
        print("withOpacity deprecations have been fixed!")
    else:
        print("No withOpacity calls found to fix.")

if __name__ == "__main__":
    main()
