#include "Logging.as";

namespace TCPR {
    const u16 MAX_REQUESTS = 100;
    const u16 REQUEST_TIMEOUT_SECS = 60;
    funcdef void CALLBACK(int, string);
    
    enum RequestState {
        REQ_UNSENT = 0,
        REQ_SENT = 1,
        REQ_ANSWERED = 2,
        REQ_TIMED_OUT = 3
    }

    shared class Request {
        string method;
        dictionary params;
        CALLBACK@ callback;

        u16 id;
        u8 state;
        u32 time_sent;

        Request(string _method, CALLBACK@ _callback) {
            method = _method;
            callback = _callback;
            state = REQ_UNSENT;
        }

        void setParam(string name, string val) {
            params.set(name, val);
        }

        string serialize() {
            string xml = "<request>";
            xml += "<id>" + id + "</id>";
            xml += "<method>" + method + "</method>";

            xml += "<params>";
            const string[]@ ks = params.getKeys();
            for (int i=0; i < ks.length(); ++i) {
                string k = ks[i];
                string val;
                params.get(k, val);
                xml += "<" + k + ">" + val + "</" + k + ">";
            }
            xml += "</params>";
            xml += "</request>";
            return xml;
        }
    }

    shared bool makeRequest(Request[]@ requests, Request@ req, string &out errMsg) {
        log("makeRequest", "Called. req.method=" + req.method);
        int id = findUnusedRequestID();
        if (!isClientConnected()) {
            errMsg = "Client is not connected!";
            log("makeRequest", "WARN " + errMsg);
            return false;
        }
        else if (id == -1) {
            errMsg = "No unused request IDs";
            log("makeRequest", "WARN " + errMsg);
            return false;
        }
        else {
            req.id = id;
            req.time_sent = Time();
            req.state = REQ_SENT;
            string ser = req.serialize();
            tcpr(ser);
            requests.push_back(req);
            log("makeRequest", "Request sent");
            return true;
        }
    }

    shared string getRequestResponse(int id) {
        return getRules().get_string(getResponseProp(id));
    }

    shared void setRequestResponse(int id, string response) {
        getRules().set_string(getResponseProp(id), response);
    }

    shared bool isClientConnected() {
        return getRules().get_bool("TCPR_CLIENT_CONNECTED");
    }

    shared int findUnusedRequestID() {
        for (int i=0; i < MAX_REQUESTS; ++i) {
            if (getRequestResponse(i).isEmpty())
                return i;
        }
        return -1;
    }

    // Should be called periodically
    void update(Request[]@ requests) {
        for (int i=(requests.length-1); i >= 0; --i) {
            Request req = requests[i];

            if (req.state == REQ_SENT) {
                string response = getRequestResponse(req.id);    
                if (!response.isEmpty()) {
                    req.callback(req.id, response);
                    log("update", "Request completed: " + req.id);
                    log("update", "Response: " + response);
                    requests.removeAt(i);
                    setRequestResponse(i, "");
                }
                else {
                    u32 time_sent = getRequestTimeSent(i);
                    if (time_now - time_sent > REQUEST_TIMEOUT_SECS) {
                        log("update", "WARN: Request timed out: " + req.id);
                        requests.removeAt(i);
                        setRequestResponse(i, "");
                    }
                }
            }
        }
    }

    shared string getResponseProp(int id) {
        return "TCPR_RES"+id;
    }
}
