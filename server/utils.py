import sys

def is_nonempty_string(x):
    return type(x) == str and len(x) > 0

def log(*msg):
    print(*msg, file=sys.stderr)

def add_dict(a, b):
    for (k, v) in b.items():
        a[k] = v
