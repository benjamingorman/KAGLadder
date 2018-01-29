def get_new_ratings(p1_rating, p2_rating, p1_score, p2_score):
    if p1_score > p2_score:
        return (p1_rating+10, p2_rating-10)
    elif p2_score > p1_score:
        return (p1_rating-10, p2_rating+10)
    else:
        return (p1_rating, p2_rating)
