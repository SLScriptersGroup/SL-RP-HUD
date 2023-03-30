#include "config.lsl"
string hash_seed = HASH_SEED;
integer meter_chan = METER_CHAN;
key http_request_id;
key toucher;

default {
    touch_start(integer total_number) {
      if (llVecDist(llGetPos(), llDetectedPos(0)) > 5) {
        llRegionSayTo(llDetectedKey(0), 0, "Must be closer to use this.");
        return;
      }
      toucher = llDetectedKey(0);
      string params = "action=w&uuid=" + (string)toucher + "&hash=" + llSHA1String((string)toucher + hash_seed);

      http_request_id = llHTTPRequest(API_URL,
                                      [
                                        HTTP_METHOD, "POST",
                                        HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                      ],
                                      params);
    }
    
    http_response(key request_id, integer status, list metadata, string body) {
      if (request_id == http_request_id) {
        if (llSubStringIndex(body, "ERR,") == 0) {
          llSay(0, "Error: " + llGetSubString(body, 4, llStringLength(body) - 1));
        } else {
          list fields = llCSV2List(llGetSubString(body, 5, llStringLength(body) - 1));
          string paid = llList2String(fields, 16);
          llRegionSayTo(toucher, 0, "You have checked in for the day and received " + CURRENCY_PREFIX + paid + CURRENCY_SUFFIX);
          llRegionSayTo(toucher, meter_chan, "1");
        }
        toucher = NULL_KEY;
      }
    }
}
