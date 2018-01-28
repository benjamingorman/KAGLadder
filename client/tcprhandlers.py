def handle_ping_request(req):
    return "<response>pong{0}</response>".format(req.params["time"])
