import unittest
import server.ratings as ratings
import random

class TestQuery(unittest.TestCase):

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
                print(p1_rating, p2_rating, p1_score, p2_score, ":", p1_new, p2_new)
