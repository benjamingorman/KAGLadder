#include "Logging.as";
#include "TCPR_Common.as";

void onInit(CRules@ this) {
    for (int i=0; i < TCPR::MAX_REQUESTS; ++i) {
        TCPR::setRequestResponse(i, "");
        TCPR::setRequestState(i, TCPR::REQ_UNUSED);
    }
}
