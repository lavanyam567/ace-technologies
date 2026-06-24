import os
import glob
import re

workflows_dir = r"d:\PDD_final\my_app\.github\workflows"
for file in glob.glob(os.path.join(workflows_dir, "*.yml")):
    with open(file, "r") as f:
        content = f.read()
    
    # Insert working directory
    if "working-directory: frontend" not in content:
        content = re.sub(r'(runs-on:\s*ubuntu-latest(?:\r?\n)(?!.*working-directory: frontend))', r'\1    defaults:\n      run:\n        working-directory: frontend\n', content)
        
    # Fix paths
    content = content.replace("path: build/web", "path: frontend/build/web")
    content = content.replace("automated_test/", "frontend/automated_test/")
    content = content.replace("selenium_tests/", "frontend/selenium_tests/")
    content = content.replace("appium_tests/", "frontend/appium_tests/")
    
    # Avoid double replacements if we ran it multiple times
    content = content.replace("frontend/frontend/", "frontend/")
    
    with open(file, "w") as f:
        f.write(content)

print("Updated workflows!")
