#!/usr/bin/env python2
import PIL.Image
import os.path

HEADS_FILES = ["Heads.png", "Heads2.png"]
HEADS_FRAME_SIZE = (16, 16)

BODIES_FILES = ["ArcherFemale.png", "ArcherMale.png", 
                "BuilderFemale.png", "BuilderMale.png", 
                "KnightMale.png", "KnightFemale.png", 
                ]
BODIES_FRAME_SIZE = (32, 32)

"""
for (i, heads_file) in enumerate(HEADS_FILES):
    image = PIL.Image.open(heads_file)
    (width, height) = image.size
    (fw, fh) = HEADS_FRAME_SIZE
    print("width {0} height {1}".format(width, height))

    head_index = 1
    for row in range(0, height/fh):
        for col in range(0, width/fw):
            # We only want the 1st frame of each head
            if col % 4 == 0:
                x = col * fw
                y = row * fh
                print(x, y)
                head_img = image.crop((x, y, x+fw, y+fh))
                head_img.save("heads/head{0}-{1}.png".format(i, head_index))
                head_index += 1
"""

for body_file in BODIES_FILES:
    image = PIL.Image.open(body_file)
    (fw, fh) = BODIES_FRAME_SIZE
    body_img = image.crop((0, 0, fw, fh))
    body_img.save("bodies/{0}".format(body_file))

