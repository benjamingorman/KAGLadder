#include "Logging.as";

namespace TCPR {
    const u16 MAX_REQUESTS = 100;
    const u16 REQUEST_TIMEOUT_SECS = 60;
    funcdef void CALLBACK(Request, string);
    
    enum RequestState {
        REQ_UNUSED = 0,
        REQ_SENT = 1,
        REQ_ANSWERED = 2
    }

    shared class Request {
        string method;
        dictionary params;
        CALLBACK@ callback;

        u16 id;
        u32 time_sent;

        Request(string _method, CALLBACK@ _callback) {
            method = _method;
            callback = _callback;
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

    shared bool makeRequest(Request[]@ requests, Request@ req) {
        log("makeRequest", "Called. req.method=" + req.method);
        int id = findUnusedRequestID();
        if (!isClientConnected()) {
            log("makeRequest", "WARN: " + "Client is not connected!");
            return false;
        }
        else if (id == -1) {
            log("makeRequest", "WARN: " + "No unused request IDs");
            return false;
        }
        else {
            req.id = id;
            req.time_sent = Time();
            setRequestState(req.id, REQ_SENT);
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

    shared u8 getRequestState(int id) {
        return getRules().get_u8(getRequestProp(id));
    }

    shared void setRequestState(int id, u8 state) {
        getRules().set_u8(getRequestProp(id), state);
    }

    shared bool isClientConnected() {
        return getRules().get_bool("TCPR_CLIENT_CONNECTED");
    }

    shared int findUnusedRequestID() {
        for (int i=0; i < MAX_REQUESTS; ++i) {
            if (getRequestState(i) == REQ_UNUSED)
                return i;
        }
        return -1;
    }

    void deleteRequest(Request[]@ requests, int reqIndex) {
        int reqID = requests[reqIndex].id;
        log("deleteRequest", "Deleting req " + reqID);
        requests.removeAt(reqIndex);
        setRequestResponse(reqID, "");
        setRequestState(reqID, REQ_UNUSED);
    }

    // Should be called periodically
    void update(Request[]@ requests) {
        for (int i=(requests.length-1); i >= 0; --i) {
            Request req = requests[i];
            bool isTimedOut = Time() - req.time_sent > REQUEST_TIMEOUT_SECS;

            if (getRequestState(req.id) == REQ_ANSWERED) {
                string response = getRequestResponse(req.id);
                req.callback(req, response);
                log("update", "Request completed: " + req.id);
                log("update", "Response: " + response);
                deleteRequest(requests, i);
            }
            else if (isTimedOut) {
                log("update", "WARN: Request timed out: " + req.id);
                deleteRequest(requests, i);
            }
        }
    }

    shared string getRequestProp(int id) {
        return "TCPR_REQ"+id;
    }

    shared string getResponseProp(int id) {
        return "TCPR_RES"+id;
    }
}
