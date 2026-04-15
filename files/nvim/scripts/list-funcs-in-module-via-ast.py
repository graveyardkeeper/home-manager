import importlib.util
import token
import sys
from tokenize import generate_tokens


def find_definitions(filename):
    with open(filename) as f:
        gen = generate_tokens(f.readline)
        for tok in gen:
            if tok[0] == token.NAME and tok[1] == "def":
                # function definition, read until next colon.
                definition, last_line = [tok[-1]], tok[3][0]
                while not (tok[0] == token.OP and tok[1] == ":"):
                    if last_line != tok[3][0]:
                        # more than one line, append, track line number
                        definition.append(tok[-1])
                        last_line = tok[3][0]
                    tok = next(gen)
                if last_line != tok[3][0]:
                    definition.append(tok[-1])
                yield "".join(definition)


def get_module_path(module):
    spec = importlib.util.find_spec(module)
    print(spec)
    if spec:
        return spec.origin


module_path = get_module_path(sys.argv[1])
if module_path:
    print(f"# {module_path}")
    # gen = find_definitions(module_path)
    # for definition in gen:
    #     print(definition.rstrip())
