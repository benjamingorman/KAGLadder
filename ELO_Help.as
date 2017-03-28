void onInit(CRules@ this) {
    SColor blue = SColor(255, 0, 0, 255);
    client_AddToChat("Welcome to the ELO mod!", blue);
    client_AddToChat("The following commands are available:", blue);
    client_AddToChat("!challenge someone", blue);
    client_AddToChat("!challenge someone archer", blue);
    client_AddToChat("!challenge someone builder", blue);
    client_AddToChat("!accept someone", blue);
    client_AddToChat("!reject someone", blue);
}