import argparse
import configparser
import os
import os.path
import re
import socket
import sys
import time
import traceback
import xmltodict
import tcprhandlers

REQ_UNUSED = 0
REQ_SENT = 1
REQ_ANSWERED = 2
SERVER_ADDR = None
CLIENT_REGION = None
KAG_IP = None
KAG_PORT = None

class TCPRRequest:
    def __init__(self, reqID, method, params):
        self.reqID = reqID
        self.method = method
        self.params = params
        self.isAnswered = False
        self.answer = ""

    @staticmethod
    def deserialize(xml):
        try:
            xml_dict = xmltodict.parse(xml)
            assert("request" in xml_dict)
            assert("id" in xml_dict["request"])
            assert("method" in xml_dict["request"])
            assert("params" in xml_dict["request"])
        except Exception as e:
            print("Could not deserialize TCPRRequest")
            print(str(e))
            print(traceback.format_exc())
            return None

        reqID = xml_dict["request"]["id"]
        method = xml_dict["request"]["method"]
        params = xml_dict["request"]["params"]
        return TCPRRequest(reqID, method, params)

def authenticate(sock):
    sock.send((RCON_PASSWORD + "\n").encode())

def send_request_response(sock, reqID, response):
    # There shouldn't be "'" symbols in the response because this interferes with the escaping.
    # Just replace them with underscores.
    response = response.replace("'", "_").replace("\n", "")
    print("    * Sending response: " + response)
    code = "getRules().set_string('TCPR_RES{0}', '{1}'); getRules().set_u8('TCPR_REQ{0}', {2});".format(
            reqID, response, REQ_ANSWERED)
    sock.send((code + "\n").encode())

def handle_request(sock, req):
    response = tcprhandlers.handle_request(req, SERVER_ADDR, CLIENT_REGION)
    send_request_response(sock, req.reqID, response)

def connect_to_kag():
    with socket.socket() as sock:
        try:
            sock.connect((KAG_IP, KAG_PORT))
        except ConnectionError:
            print("Couldn't connect to KAG at {0}:{1}. Is the server running?".format(KAG_IP, KAG_PORT))
            return

        print("Connected.")
        authenticate(sock)
        print("Authenticated.")
        print("Listening...")

        in_request = False
        request_lines = []
        for line in sock.makefile('r'):
            print("  RECEIVED: {}".format(line.strip()))
            if re.match("^\d\d:\d\d:\d\dTCPR: server shutting down.", line):
                print("Detected server shutdown so closing socket")
                break
            elif re.match("^\[\d\d:\d\d:\d\d\]\s<multiline>", line):
                print("Detected request start")
                in_request = True
            elif re.match("^\[\d\d:\d\d:\d\d\]\s</multiline>", line):
                print("Detected request end")
                with open("requestdata.tmp.txt", "w") as f:
                    f.write("".join(request_lines))
                in_request = False
                req = TCPRRequest.deserialize("".join(request_lines))
                handle_request(sock, req)
                request_lines.clear()
            elif in_request:
                match = re.match("^\[\d\d:\d\d:\d\d\]\s(.*)$", line)
                if match: # this should always be the case
                    tcpr_content = match.group(1)
                    request_lines.append(tcpr_content)
        
        sock.close()
        print("KAG connection closed")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", required=True, help="Path to config file")
    args = parser.parse_args()

    assert(os.path.isfile(args.config))

    config = configparser.ConfigParser()
    config.read(args.config)

    SERVER_ADDR = config["CLIENT"]["SERVER_ADDR"]
    CLIENT_REGION = "EU"
    KAG_IP = config["EU"]["KAG_IP"]
    KAG_PORT = int(config["EU"]["KAG_PORT"])
    RCON_PASSWORD = config["EU"]["RCON_PASSWORD"]

    print("Initialized")
    while True:
        try:
            connect_to_kag()
            time.sleep(3)
        except Exception as e:
            print("ERROR: Uncaught exception! Connecting again...")
            print(e)
            print(traceback.format_exc())
            time.sleep(1)
        sys.stdout.flush()
