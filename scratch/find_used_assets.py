import glob, re

dart_files = glob.glob('lib/**/*.dart', recursive=True)
used = set()
for f in dart_files:
    content = open(f, encoding='utf-8', errors='ignore').read()
    matches = re.findall(r"['\"]([^'\"]*assets[^'\"]*)['\"]", content)
    for m in matches:
        used.add(m)

print("ACTUALLY REFERENCED ASSETS IN CODE:")
for u in sorted(used):
    print(f"  {u}")
