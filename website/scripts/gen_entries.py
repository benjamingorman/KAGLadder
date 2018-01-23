import sys
import random
import json

N_ENTRIES = int(sys.argv[1])
SAVE_FILE = "sampleEntries.js"

def load_names(file_path):
    names = []
    with open(file_path, 'r') as f:
        for line in f:
            names.append(line.strip())
    return names


def rand_bool():
    return bool(random.getrandbits(1))

def gen_entries(n):
    entries = []
    entry = {}

    male_names = load_names("male_names.txt")
    female_names = load_names("female_names.txt")
    kag_classes = ["archer", "builder", "knight"]

    for i in range(n):
        entry = {}
        if rand_bool():
            entry["gender"] = "male"
            entry["name"] = random.choice(male_names)
        else:
            entry["gender"] = "female"
            entry["name"] = random.choice(female_names)

        entry["kagClass"] = random.choice(kag_classes)
        entry["wins"] = random.randint(0, 301)
        entry["losses"] = random.randint(0, 301)
        entry["rating"] = random.randint(100, 3000)
        entry["head"] = random.randint(1, 170)

        entries.append(entry)

    with open(SAVE_FILE, 'w') as f:
        f.write("let sampleEntries = {};\nexport default sampleEntries".format(json.dumps(entries, indent=4)))
    print("Saved to " + SAVE_FILE)

gen_entries(N_ENTRIES)
