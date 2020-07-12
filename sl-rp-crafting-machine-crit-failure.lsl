#include "config.lsl"
string machine_name = "__ENTER_NAME_FOR_LOGGING__";
key http_request_id;
string hash_seed = HASH_SEED;
default {
  link_message(integer sender_num, integer num, string produced_item, key toucher) {
    if (llGetInventoryType(produced_item) == INVENTORY_NONE) {
      llSay(0, "Unable to find " + produced_item + "!");
    } else {
      llGiveInventory(toucher, produced_item);
        string params = "uuid=" + (string)toucher + "&hash=" + llSHA1String((string)toucher + hash_seed)
                      + "&action=c&is_crit_fail=Yes&item=" + produced_item + "&source=" + machine_name;
        http_request_id = llHTTPRequest(API_URL,
                                        [
                                          HTTP_METHOD, "POST",
                                          HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                        ],
                                        params);

    }
  }
}
