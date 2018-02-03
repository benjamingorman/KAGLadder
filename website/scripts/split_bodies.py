import PIL.Image
import os.path

BODIES_FILES = ["ArcherFemale.png", "ArcherMale.png", 
                "BuilderFemale.png", "BuilderMale.png", 
                "KnightMale.png", "KnightFemale.png", 
                ]
BODIES_FRAME_SIZE = (32, 32)

for body_file in BODIES_FILES:
    image = PIL.Image.open(body_file)
    (fw, fh) = BODIES_FRAME_SIZE
    body_img = image.crop((0, 0, fw, fh))
    body_img.save("bodies/{0}".format(body_file))
