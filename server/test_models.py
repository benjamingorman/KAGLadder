import unittest
from server.models import *

class TestModelPlayer(unittest.TestCase):
    def test_cls_get_fields(self):
        fields = Player.get_fields()
        self.assertTrue("username" in fields)
        self.assertTrue(fields["username"].index == 0)
        self.assertTrue("nickname" in fields)
        self.assertTrue(fields["nickname"].index == 1)
        self.assertTrue("clantag" in fields)
        self.assertTrue(fields["clantag"].index == 2)
        self.assertTrue(len(fields) == 5)

    def test_instantiate(self):
        p = Player()
        p.username = "Eluded"
        self.assertEqual(p.username, "Eluded")

    def test_validate(self):
        p = Player()
        p.username = "Eluded"
        p.nickname = "Joan of Arc"
        p.clantag = "TRUTH"
        p.gender = 1
        p.head = 10
        self.assertTrue(p.validate())

    def test_from_row(self):
        row = ("Eluded", "Joan of Arc", "TRUTH", 0, 0)
        p = Player.from_row(row)
        self.assertEqual(p.username, "Eluded")
        self.assertEqual(p.nickname, "Joan of Arc")
        self.assertEqual(p.clantag, "TRUTH")
        self.assertEqual(p.gender, 0)
        self.assertEqual(p.head, 0)

    def test_from_dict(self):
        d = {"username": "Eluded",
             "nickname": "Joan of Arc",
             "clantag": "TRUTH",
             "gender": 0,
             "head": 0
             }
        p = Player.from_dict(d)
        self.assertEqual(p.username, "Eluded")
        self.assertEqual(p.nickname, "Joan of Arc")
        self.assertEqual(p.clantag, "TRUTH")
        self.assertEqual(p.gender, 0)
        self.assertEqual(p.head, 0)
