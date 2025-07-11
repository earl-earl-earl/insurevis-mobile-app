#!/usr/bin/env python3
"""
Script to add mounted checks before Navigator and ScaffoldMessenger calls
to fix use_build_context_synchronously warnings.
"""

import os
import re
import glob

def add_mounted_checks(file_path):
    """Add mounted checks before async context usage."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        # Pattern to match Navigator calls that need mounted checks
        nav_pattern = r'(\s+)(Navigator\.[a-zA-Z]+\(\s*context)'
        content = re.sub(nav_pattern, r'\1if (mounted) {\n\1  \2', content)
        
        # Add closing braces for Navigator calls
        content = re.sub(r'(Navigator\.[a-zA-Z]+\([^;]*context[^;]*;)', r'\1\n    }', content)
        
        # Pattern for ScaffoldMessenger calls
        scaffold_pattern = r'(\s+)(ScaffoldMessenger\.of\(context\))'
        content = re.sub(scaffold_pattern, r'\1if (mounted) {\n\1  \2', content)
        
        # Add closing braces for ScaffoldMessenger calls that end with );
        content = re.sub(r'(ScaffoldMessenger\.of\(context\)[^;]*\);)', r'\1\n      }', content)
        
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(content)
        
        return True
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Main function to process specific Dart files with async issues."""
    # Get the directory where this script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    lib_dir = os.path.join(script_dir, "lib")
    
    # Files that are known to have async context issues
    target_files = [
        "lib/main-screens/documents_screen.dart",
        "lib/other-screens/camera.dart",
        "lib/other-screens/result_screen.dart",
        "lib/other-screens/multiple_results_screen.dart",
    ]
    
    fixed_files = []
    
    for file_rel_path in target_files:
        file_path = os.path.join(script_dir, file_rel_path)
        if os.path.exists(file_path):
            if add_mounted_checks(file_path):
                fixed_files.append(file_path)
                print(f"Added mounted checks to: {file_rel_path}")
    
    print(f"\nTotal files fixed: {len(fixed_files)}")
    if len(fixed_files) > 0:
        print("Mounted checks have been added!")

if __name__ == "__main__":
    main()
