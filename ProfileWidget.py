from PIL import Image, ImageDraw, ImageFont
from flask import Flask, send_file
from tempfile import NamedTemporaryFile, TemporaryFile

ELO_TABLE_FILE = "Example_ELO_Table.cfg"
WIDGET_WIDTH = 280
WIDGET_HEIGHT = 100
WIDGET_FONT_HEADER = ImageFont.truetype("FjallaOne-Regular.ttf", 18)
WIDGET_FONT_BODY = ImageFont.truetype("FjallaOne-Regular.ttf", 14)


def get_rating(player_username):
    rating_archer = "Unrated"
    rating_builder = "Unrated"
    rating_knight = "Unrated"
    with open(ELO_TABLE_FILE, 'r') as f:
        for line in f:
            name_with_class, elo = line.split("=")
            name_with_class = name_with_class.strip()
            elo = elo.strip()

            username, which_class = name_with_class.split("-")
            which_class.strip()
            #print(name_with_class, username, which_class, elo)

            if username == player_username:
                if which_class == "archer":
                    rating_archer = elo
                elif which_class == "builder":
                    rating_builder = elo
                elif which_class == "knight":
                    rating_knight = elo

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


# Use a pool of temporary files
widget_counter = 0
widget_pool_size = 30

app = Flask(__name__)
@app.route("/rating/<username>")
def get_elo_widget_image(username):
    print("Getting widget for: " + username)
    global widget_counter
    global widget_pool_size
    image_file_name = "tempwidget{0}.png".format(widget_counter % widget_pool_size)
    widget_counter += 1

    create_elo_widget_image(username, image_file_name)
    return send_file(image_file_name, mimetype="image/png")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=9000)