import unittest
import server.ratings as ratings
import random

class TestQuery(unittest.TestCase):

    def test_get_odds_from_win_prob(self):
        p = 0.1
        while p <= 0.9:
            odds = ratings.get_odds_from_win_prob(p)
            print(p, odds)
            p += 0.1

    def test_get_win_probabilities(self):
        examples = [
            (1000, 1500, 0, 0, 5),
            (1100, 1500, 0, 0, 5),
            (1200, 1500, 0, 0, 5),
            (1200, 1500, 1, 0, 5),
            (1200, 1500, 2, 0, 5),
            (1200, 1500, 3, 0, 5),
            (1500, 1000, 0, 0, 5),
            (1500, 1100, 0, 0, 5),
            (1500, 1200, 0, 0, 5),
            (1500, 1200, 1, 0, 5),
            (1500, 1200, 2, 0, 5),
            (1000, 2000, 0, 0, 5)
        ]
        for (p1, p2, p1_s, p2_s, dts) in examples:
            (win_p1, win_p2) = ratings.get_win_probabilities(p1, p2, p1_s, p2_s, dts)
            p1_odds = ratings.get_odds_from_win_prob(win_p1)
            p2_odds = ratings.get_odds_from_win_prob(win_p2)
            print("elo ({0}, {1}) score ({2}, {3}) duel_to {4}".format(p1, p2, p1_s, p2_s, dts))
            print("wins {0}%, {1}%".format(win_p1*100, win_p2*100))
            print("odds 1:{0}, 1:{1}".format(p1_odds, p2_odds))

    def test_winner_doesnt_lose_elo(self):
        for _ in range(100):
            p1_rating = random.randint(100, 3000)
            p2_rating = random.randint(100, 3000)
            # scores should be different
            [p1_score, p2_score] = random.sample(range(0, 11), 2)
            (p1_new, p2_new) = ratings.get_new_ratings(p1_rating, p2_rating, p1_score, p2_score)
            try:
                if p1_score > p2_score:
                    self.assertGreater(p1_new, p1_rating)
                    self.assertLess(p2_new, p2_rating)
                if p2_score > p1_score:
                    self.assertGreater(p2_new, p2_rating)
                    self.assertLess(p1_new, p1_rating)
            except AssertionError:
                print(p1_rating, p2_rating, p1_score, p2_score)
                raise
            finally:
                #print(p1_rating, p2_rating, p1_score, p2_score, ":", p1_new, p2_new)
                pass
