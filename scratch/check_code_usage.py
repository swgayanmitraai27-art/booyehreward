import glob, os

files = glob.glob('lib/**/*.dart', recursive=True)
all_contents = {}
for f in files:
    with open(f, encoding='utf-8') as fp:
        all_contents[f] = fp.read()

print("=== CHECKING FILE USAGE ===")
for f in files:
    base = os.path.basename(f)
    if base == 'main.dart':
        continue
    # check if base is imported anywhere
    imported_by = []
    for other_f, content in all_contents.items():
        if other_f == f:
            continue
        if base in content:
            imported_by.append(os.path.basename(other_f))
    print(f"{base:30} : Imported by {imported_by if imported_by else 'NONE (POTENTIALLY DEAD)'}")
