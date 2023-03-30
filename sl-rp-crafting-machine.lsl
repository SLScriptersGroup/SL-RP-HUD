#include "config.lsl"
string machine_name = "__ENTER_NAME_FOR_LOGGING__";
//Strided list of the format "_ITEM_NAME_", (integer)qty_required, 0
list ingredients = [
];
string produced_item = "__ENTER_NAME_OF_INVENTORY_OBJECT_TO_DELIVER_WHEN_ALL_INGREDIENTS_ARE_PRESENT__";
integer min_level = 1;
string failure_message = "";

integer success_rate = 95;
integer crit_fail_rate = 10;
integer crit_fail_rate_damping_by_level_above_min_level = 3;

string allowed_region = ALLOWED_REGION;
list creators = [CREATORS];
string hash_seed = HASH_SEED;
key toucher = NULL_KEY;
list creator_keys;
key http_request_id;
integer dialog_listener;
integer dialog_chan;
integer max_qty;
integer level;
integer is_someone_present;

default {
  state_entry() {
    llAllowInventoryDrop(TRUE);
    llVolumeDetect(TRUE);

    integer i;
    for (;i<llGetListLength(creators);i++) {
      creator_keys += [llList2Key(creators, i)];
    }

    dialog_chan = (integer)llFrand(DEBUG_CHANNEL)*-1;
    is_someone_present = FALSE;
  }
  collision_start(integer num) {
    if (is_someone_present) return;
    integer j;
    integer ing_qty = llGetListLength(ingredients);
    float required;
    string output = "Hello. I am " + machine_name + ". I can produce the " + produced_item + ".\n \nEach " + produced_item + " requires the following ingredients:\n";
    for (j=0;j<ing_qty;j+=3) {
      required = llList2Float(ingredients, j + 1);
      output += (string)((integer)required) + " × " + llList2String(ingredients, j) + "\n";
    }
    llRegionSayTo(llDetectedKey(0), 0, output + "\nAdd the ingredients to the case and then touch the console to begin production.\n \n(( Please add items by editing and opening the Content tab of this object. [Do not Ctrl+Drag-and-Drop.] Items will not be returned. ))");
    is_someone_present = TRUE;
  }
  collision_end(integer num) {
    is_someone_present = FALSE;
  }
  touch_start(integer total_number) {
    if (llGetRegionName() == allowed_region) {
      float time = llGetTime();
      toucher = llDetectedKey(0);
      if (llVecDist(llGetPos(), llDetectedPos(0)) > 5) {
          llRegionSayTo(toucher, 0, "Must be closer to use this.");
          return;
      }

      string params = "action=r&uuid=" + (string)toucher + "&hash=" + llSHA1String((string)toucher + hash_seed);

      http_request_id = llHTTPRequest(API_URL,
                                      [
                                        HTTP_METHOD, "POST",
                                        HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                      ],
                                      params);
    } else {
      llRegionSayTo(llDetectedKey(0), 0, "You must be on " + allowed_region + " to use this.");
    }
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id == http_request_id) {
      if (llSubStringIndex(body, "ERR,") == 0) {
        if (toucher == NULL_KEY) {
          llSay(0, "Error: " + llGetSubString(body, 4, llStringLength(body) - 1));
        } else {
          llRegionSayTo(toucher, 0, "Error: " + llGetSubString(body, 4, llStringLength(body) - 1));
        }
        llSetTimerEvent(0.1);
      } else if (llSubStringIndex(body, "STAT,") == 0) {
        list fields = llCSV2List(llGetSubString(body, 5, llStringLength(body) - 1));
        integer experience = llList2Integer(fields, 3);
        integer level = llList2Integer(fields, 14);
        if (level >= min_level) {
          integer qty = llGetInventoryNumber(INVENTORY_OBJECT);
          integer ing_qty = llGetListLength(ingredients);
          integer i; integer j;
          string name;
          for (i=0;i<ing_qty;i+=3) {
            ingredients = llListReplaceList(ingredients, [0], i + 2, i + 2);
          }
          for (i=0;i<qty;i++) {
            name = llGetInventoryName(INVENTORY_OBJECT, i);
            if (name != produced_item && llListFindList(creator_keys, [llGetInventoryCreator(name)]) > -1) {
              for (j=0;j<ing_qty;j+=3) {
                if (llSubStringIndex(name, llList2String(ingredients, j)) == 0) {
                  ingredients = llListReplaceList(ingredients, [llList2Integer(ingredients, j + 2) + 1], j + 2, j + 2);
                }
              }
            }
          }
          integer num_to_make = 999999;
          float required;
          float possess;
          integer can_make;
          string output = "\nEach " + produced_item + " requires the following ingredients:\n";
          for (j=0;j<ing_qty;j+=3) {
            required = llList2Float(ingredients, j + 1);
            possess = llList2Float(ingredients, j + 2);
            can_make = llFloor(possess/required);
            if (can_make < num_to_make) {
              num_to_make = can_make;
            }
            output += (string)((integer)required) + " × " + llList2String(ingredients, j) + "\n";
          }
          max_qty = num_to_make;
          llRegionSayTo(toucher, 0, output);
          if (num_to_make > 0) {
            dialog_listener = llListen(dialog_chan, "", toucher, "");
            llSetTimerEvent(60);
            llTextBox(toucher, "\nYou can make " + (string)num_to_make + " " + produced_item + "\n \nHow many would you like to make?", dialog_chan);
          } else {
            llRegionSayTo(toucher, 0, "There are not enough items in the case to make one " + produced_item + ". \n \nAdd the ingredients to the case and then touch the console to begin production.\n \n(( Please add items by editing and opening the Content tab of this object. [Do not Ctrl+Drag-and-Drop.] Items will not be returned. ))");
            llSetTimerEvent(0.1);
          }
        } else {
          llRegionSayTo(toucher, 0, "You do not have the minimum required experience.");
          llSetTimerEvent(0.1);
        }
      } else if (body != "SILENT") {
        if (llSubStringIndex(body, "GIVE,") < 0) {
          if (toucher == NULL_KEY) {
            llSay(0, "Unexpected response: " + body);
          } else {
            llRegionSayTo(toucher, 0, "Unexpected response: " + body);
          }
        }
        llSetTimerEvent(0.1);
      }
    }
  }
  listen(integer channel, string name, key id, string message) {
    if (channel == dialog_chan) {
      llSetTimerEvent(0);
      integer num = (integer)message;
      if (num > 0 && num <= max_qty) {
        llRegionSayTo(toucher, 0, "Making " + (string)num + " " + produced_item + ". (It takes 2 seconds for each one to be created.)");
        integer qty = llGetInventoryNumber(INVENTORY_OBJECT);
        integer i; integer j; integer k;
        integer ing_qty = llGetListLength(ingredients);
        string item; integer item_qty;
        for (i=0;i<ing_qty;i+=3) {
          ingredients = llListReplaceList(ingredients, [num * llList2Integer(ingredients, i  + 1)], i + 2, i + 2);
        }
        
        list deletes = [];

        for (j=0;j<qty;j++) {
          item = llGetInventoryName(INVENTORY_OBJECT, j);
          for (k=0;k<ing_qty;k+=3) {
            item_qty = llList2Integer(ingredients, k+2);
            if (
                 llSubStringIndex(item, llList2String(ingredients, k)) > -1
                 && item_qty > 0
               ) {
              deletes += [item];
              ingredients = llListReplaceList(ingredients, [item_qty - 1], k + 2, k + 2);
            }
          }
        }
        for (j=0;j<llGetListLength(deletes);j++) {
          llRemoveInventory(llList2String(deletes, j));
        }
        for (i=0;i<num;i++) {
          if (llRound(llFrand(100)) > success_rate) {
            //Did not succeed
            integer c_fail_rate = crit_fail_rate - (level - min_level) * crit_fail_rate_damping_by_level_above_min_level;
            if (c_fail_rate > 0) {
              if (llRound(llFrand(100)) <= c_fail_rate) {
                //Critical failure -- deliver bad product
                llMessageLinked(LINK_ALL_OTHERS, 0, produced_item, toucher);
              } else {
                integer index;
                while ((index = llSubStringIndex(failure_message, "ITEM_NAME")) > -1) {
                  failure_message = llGetSubString(failure_message, 0, index - 1) + produced_item + llGetSubString(failure_message, index + 9, llStringLength(failure_message) - 1);
                }
                llRegionSayTo(toucher, 0, failure_message);
              }
            } else {
              integer index;
              while ((index = llSubStringIndex(failure_message, "ITEM_NAME")) > -1) {
                failure_message = llGetSubString(failure_message, 0, index - 1) + produced_item + llGetSubString(failure_message, index + 9, llStringLength(failure_message) - 1);
              }
              llRegionSayTo(toucher, 0, failure_message);
            }
          } else {
            llGiveInventory(toucher, produced_item);
            string params = "uuid=" + (string)toucher + "&hash=" + llSHA1String((string)toucher + hash_seed)
                          + "&action=c&is_crit_fail=No&item=" + produced_item + "&source=" + machine_name
                          + "&min_level=" + (string)min_level;
            http_request_id = llHTTPRequest(API_URL,
                                            [
                                              HTTP_METHOD, "POST",
                                              HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                            ],
                                            params);
          }
        }
        toucher = NULL_KEY;
        llRegionSayTo(toucher, 0, "Production of " + (string)num + " " + produced_item + " complete.");
        llSetTimerEvent(0.1);
        llResetTime();
      } else {
        llRegionSayTo(toucher, 0, "You did not pick a number between 1 and " + (string)max_qty + ".");
        llSetTimerEvent(0.1);
      }
      max_qty = 0;
      llListenRemove(dialog_listener);
    }
  }
  timer() {
    max_qty = 0;
    if (toucher == NULL_KEY) {
      llSay(0, "Processing complete.");
    } else {
      llRegionSayTo(toucher, 0, "Processing complete.");
    }
    llListenRemove(dialog_listener);
    llSetTimerEvent(0);
    toucher = NULL_KEY;
  }
}
