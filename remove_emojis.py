"""
Script to remove emojis from logger statements to fix Windows charmap encoding issues.
"""

import re
from pathlib import Path

# Emoji to text replacements
EMOJI_REPLACEMENTS = {
    "📁": "[DIR]",
    "🔐": "[VAULT]",
    "✅": "[OK]",
    "❌": "[ERROR]",
    "🗑️": "[DELETE]",
    "🧪": "[TEST]",
    "📊": "[HASH]",
    "🔒": "[ENCRYPT]",
    "🔓": "[DECRYPT]",
    "🚫": "[BLOCKED]",
    "🛡️": "[SHIELD]",
    "📝": "[LOG]",
    "🚨": "[ALERT]",
    "🔍": "[SCAN]",
    "⚠️": "[WARNING]",
    "🎯": "[TARGET]",
    "📥": "[IN]",
    "📤": "[OUT]",
    "🖼️": "[IMAGE]",
    "ℹ️": "[INFO]",
}

def remove_emojis_from_file(file_path: Path):
    """Remove emojis from a Python file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Replace each emoji with its text equivalent
        for emoji, replacement in EMOJI_REPLACEMENTS.items():
            content = content.replace(emoji, replacement)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated: {file_path}")
            return True
        return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    backend_dir = Path("backend")
    tests_dir = Path("tests")
    
    updated_count = 0
    
    # Process all Python files in backend
    for py_file in backend_dir.rglob("*.py"):
        if remove_emojis_from_file(py_file):
            updated_count += 1
    
    # Process all Python files in tests
    for py_file in tests_dir.rglob("*.py"):
        if remove_emojis_from_file(py_file):
            updated_count += 1
    
    print(f"\nTotal files updated: {updated_count}")

if __name__ == "__main__":
    main()
