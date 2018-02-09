#!/usr/bin/env python2
import PIL.Image
import os.path
import sys
import math

HEADS_FILES = ["Heads.png", "Heads2.png"]
HEADS_FRAME_SIZE = (16, 16)

def get_head_index(head_file, row, col):
    i = int(col / 4) + row * 8
    print(i)

    if i <= 28:
        return i
    elif i == 29:
        return -1
    elif i >= 30:
        # Male and female heads should have same number
        i = int(math.ceil((i-30) / 2)) + 30

        if i == 30:
            return 255
        else:
            maxHead = 0
            offset = 0
            if head_file == "Heads.png":
                maxHead = 99
                offset = 0
            elif head_file == "Heads2.png":
                maxHead = 363
                offset = 256 

            if i + offset > maxHead:
                return -1
            else:
                return i + offset

def get_gender_index(head_file, row, col):
    i = int(col / 4) + row * 8

    if i % 2 == 0:
        return 0
    else:
        return 1
    return -1

for (i, heads_file) in enumerate(HEADS_FILES):
    image = PIL.Image.open(heads_file)
    (width, height) = image.size
    (fw, fh) = HEADS_FRAME_SIZE
    print("width {0} height {1}".format(width, height))

    head_index = 1
    gender_index = 0
    for row in range(0, height/fh):
        for col in range(0, width/fw):
            # We only want the 1st frame of each head
            if col % 4 == 0:
                x = col * fw
                y = row * fh
                head_img = image.crop((x, y, x+fw, y+fh))

                head_index = get_head_index(heads_file, row, col)
                gender_index = get_gender_index(heads_file, row, col)

                print(row, col, head_index, gender_index)

                if head_index == -1:
                    continue
                elif head_index < 31:
                    save_dir = "custom"
                elif gender_index == 0:
                    save_dir = "male"
                else:
                    save_dir = "female"
                    
                save_path = "heads/{0}/{1}.png".format(save_dir, head_index)
                head_img.save(save_path)
