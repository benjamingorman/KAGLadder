import unittest
import server.queries as queries

class TestQuery(unittest.TestCase):
    def test_integration(self):
        q = queries.get_player

        params = q.get_params_template() 
        self.assertEqual(len(params), 1)
        self.assertEqual(params["username"], None)
        self.assertEqual(q.get_required_param_names(), set(["username"]))

        params_tuple = q.build_params_tuple({"username": "Eluded"})
        self.assertEqual(len(params_tuple), 1)
        self.assertEqual(params_tuple[0], "Eluded")

        with self.assertRaises(ValueError):
            q.build_params_tuple({"foo": "bar"})

        with self.assertRaises(ValueError):
            q.build_params_tuple({"username": "!!!"})

        example_row = ("Eluded", "Joan of Arc", "TRUTH", None, "255")
        loaded = q.load_result_tuple(example_row)

        self.assertEqual(len(loaded), 5)
        self.assertEqual(loaded["username"], "Eluded")
        self.assertEqual(loaded["gender"], None)
        self.assertEqual(loaded["head"], 255)

    def test_recent_match_history(self):
        self.assertEqual(len(queries.get_recent_match_history.result_fields), 8)
