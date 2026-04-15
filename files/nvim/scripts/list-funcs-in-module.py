import sys
import importlib
import inspect


def print_definitions(module_name):
    module = importlib.import_module(module_name)
    print(f"# {module.__file__}")
    members = inspect.getmembers(module)
    for k, v in members:
        if inspect.isfunction(v):
            sig = inspect.signature(v)
            print(f"def {k}{sig}:")


module_name = sys.argv[1]
print_definitions(module_name)
