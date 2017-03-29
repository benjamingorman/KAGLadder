from PIL import Image, ImageDraw, ImageFont
from flask import Flask, send_file
from tempfile import NamedTemporaryFile, TemporaryFile
import sys
import os

ELO_TABLE_FILE = "Example_ELO_Table.cfg"
WIDGET_WIDTH = 280
WIDGET_HEIGHT = 100
WIDGET_FONT_HEADER = ImageFont.truetype("FjallaOne-Regular.ttf", 18)
WIDGET_FONT_BODY = ImageFont.truetype("FjallaOne-Regular.ttf", 14)

LEADERBOARD_WIDTH = 250
LEADERBOARD_ROW_HEIGHT = 18

class PlayerRating:
    def __init__(self, username, whichclass, rating):
        self.username = username
        self.whichclass = whichclass
        self.rating = rating

    @staticmethod
    def from_elo_table_line(line):
        name_with_class, rating = line.split("=")
        name_with_class = name_with_class.strip()
        rating = rating.strip()

        username, whichclass = name_with_class.split("-")
        whichclass.strip()
        
        return PlayerRating(username, whichclass, rating)

def get_rating(player_username):
    rating_archer = "Unrated"
    rating_builder = "Unrated"
    rating_knight = "Unrated"
    with open(ELO_TABLE_FILE, 'r') as f:
        for line in f:
            pr = PlayerRating.from_elo_table_line(line)

            if pr.username == player_username:
                if pr.whichclass == "archer":
                    rating_archer = pr.rating
                elif pr.whichclass == "builder":
                    rating_builder = pr.rating
                elif pr.whichclass == "knight":
                    rating_knight = pr.rating

    return (rating_archer, rating_builder, rating_knight)


def create_elo_widget_image(username, file_handle):
    img = Image.new('RGB', (WIDGET_WIDTH, WIDGET_HEIGHT))
    draw = ImageDraw.Draw(img)
    header_color = (255, 0, 0)
    class_color = (135, 206, 235)
    body_color = (255, 255, 255)

    (rating_archer, rating_builder, rating_knight) = get_rating(username)
    draw.text((20, 20), "Rated 1v1 Server - " + username, font=WIDGET_FONT_HEADER, fill=header_color)
    draw.text((20, 50), "Archer", font=WIDGET_FONT_BODY, fill=class_color)
    draw.text((20, 70), rating_archer, font=WIDGET_FONT_BODY, fill=body_color)
    draw.text((80, 50), "Builder", font=WIDGET_FONT_BODY, fill=class_color)
    draw.text((80, 70), rating_builder, font=WIDGET_FONT_BODY, fill=body_color)
    draw.text((140, 50), "Knight", font=WIDGET_FONT_BODY, fill=class_color)
    draw.text((140, 70), rating_knight, font=WIDGET_FONT_BODY, fill=body_color)
    img.save(file_handle, "PNG")

def create_leaderboard_image(whichclass, file_handle):
    leaderboard = [] # list of PlayerRatings

    with open(ELO_TABLE_FILE, 'r') as f:
        for line in f:
            pr = PlayerRating.from_elo_table_line(line)
            if pr.whichclass == whichclass:
                leaderboard.append(pr)

    leaderboard.sort(key=lambda pr: int(pr.rating), reverse=True)
    #print(leaderboard)

    img = Image.new('RGB', (LEADERBOARD_WIDTH, len(leaderboard) * LEADERBOARD_ROW_HEIGHT + 60))
    draw = ImageDraw.Draw(img)
    header_color = (255, 0, 0)
    rating_color = (135, 206, 235)
    body_color = (255, 255, 255)

    #longest_username_length = max(map(lambda pr: len(pr.username), leaderboard))

    draw.text((20, 20), whichclass.capitalize() + " Leaderboard", font=WIDGET_FONT_HEADER, fill=header_color)
    row_start_y = 50
    for (i, pr) in enumerate(leaderboard):
        text = "{0}.    {1}".format(i+1, pr.username)
        rating_text = pr.rating
        draw.text((20, row_start_y + i*LEADERBOARD_ROW_HEIGHT), text, font=WIDGET_FONT_BODY, fill=body_color)
        draw.text((150, row_start_y + i*LEADERBOARD_ROW_HEIGHT), rating_text, font=WIDGET_FONT_BODY, fill=rating_color)
    img.save(file_handle, "PNG")


# Use a pool of temporary files
widget_counter = 0
widget_pool_size = 30

def get_temp_image_name():
    global widget_counter
    global widget_pool_size
    widget_counter += 1
    return "tempwidget{0}.png".format(widget_counter % widget_pool_size)

app = Flask(__name__)
@app.route("/rating/<username>")
def get_elo_widget_image(username):
    print("Getting widget for: " + username)
    image_file_name = get_temp_image_name()
    create_elo_widget_image(username, image_file_name)
    return send_file(image_file_name, mimetype="image/png")

@app.route("/leaderboard/<whichclass>")
def get_leaderboard_image(whichclass):
    print("Getting leaderboard for: " + whichclass)
    image_file_name = get_temp_image_name()
    create_leaderboard_image(whichclass, image_file_name)
    return send_file(image_file_name, mimetype="image/png")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        ELO_TABLE_FILE = sys.argv[1]
        assert(os.path.isfile(ELO_TABLE_FILE))
    app.run(host='0.0.0.0', port=9000)