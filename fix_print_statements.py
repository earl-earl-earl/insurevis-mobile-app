#!/usr/bin/env python3
"""
Script to remove print statements from Flutter project and replace with proper logging.
Removes print() calls or comments them out for production code.
"""

import os
import re
import glob

def fix_print_statements_in_file(file_path):
    """Remove or comment out print statements in a single file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        modified = False
        new_lines = []
        
        for line in lines:
            # Check if line contains print statement
            if re.search(r'print\s*\(', line):
                # Check if it's already commented
                if not line.strip().startswith('//'):
                    # Comment out the print statement instead of removing
                    indent = len(line) - len(line.lstrip())
                    new_line = ' ' * indent + '// DEBUG: ' + line.lstrip()
                    new_lines.append(new_line)
                    modified = True
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        
        if modified:
            with open(file_path, 'w', encoding='utf-8') as file:
                file.writelines(new_lines)
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
        if fix_print_statements_in_file(dart_file):
            fixed_files.append(dart_file)
            print(f"Fixed print statements in: {os.path.relpath(dart_file, script_dir)}")
    
    print(f"\nTotal files with print statements fixed: {len(fixed_files)}")
    if len(fixed_files) > 0:
        print("Print statements have been commented out for production!")
    else:
        print("No print statements found to fix.")

if __name__ == "__main__":
    main()
