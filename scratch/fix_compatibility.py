import os
import re

def fix_flutter_compatibility():
    lib_dir = r'c:\Users\Lenovo\OneDrive\Desktop\B1 French Flutter\french_course_b1\lib'
    
    # Regex to find .withValues(alpha: 0.X) and convert to .withOpacity(0.X)
    pattern = re.compile(r'\.withValues\(alpha:\s*([\d\.]+)\)')
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = pattern.sub(r'.withOpacity(\1)', content)
                
                if new_content != content:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    print(f"Fixed compatibility in: {file}")

if __name__ == "__main__":
    fix_flutter_compatibility()
