import pkgutil

for importer, modname, ispkg in pkgutil.walk_packages(onerror=lambda x: None):
    if modname.startswith("_") or "._" in modname or "test" in modname:
        continue
    print(modname)
