import sys

def is_nonempty_string(x):
    return type(x) == str and len(x) > 0

def log(*msg):
    print(*msg, file=sys.stderr)
