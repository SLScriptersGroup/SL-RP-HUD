#include "config.lsl"

string allowed_region = ALLOWED_REGION;
list creators = [CREATORS];
string hash_seed = HASH_SEED;
integer meter_chan = METER_CHAN;
key http_request_id;
list creator_keys;
string character;
string title;
integer currency_banked = -1;
integer experience;
integer level;
integer xp_needed;
integer health;
integer attack;
integer defense;
integer boost_attack; //Not implemented
integer boost_defense; //Not implemented
integer attackable; //Not fully implemented
vector hover_color;
integer is_ooc;
integer is_afk;
integer dialog_listener;
string dialog_state;
integer dialog_chan;
integer dialog_page = 1;
string dialog_prompt;
key owner;
integer scanning_for_payees;
list nearby_players;
integer pay_person_idx;
integer scanning_for_victims;
integer attack_person_idx;
key requesting_attacker;
string attack_type;
integer update_chan = HUD_UPDATE_CHAN;
integer update_listener;
integer is_current_version;
string update_msg;
setTitle() {
 string hover_text = "";
  float alpha = 1;
  vector col = hover_color;
  if (is_current_version) {
    hover_text = "\n" + CURRENCY_PREFIX + (string)currency_banked + CURRENCY_SUFFIX
               + "\nLevel: " + (string)level + " XP: " + (string)experience + "/" + (string)xp_needed
               + "\nHealth: " + (string)health + "/10"
               + "\nAttack: " + (string)attack
               + "\nDefense: " + (string)defense;

    if (is_ooc) {
      hover_text += "\n (( OOC ))";
    }
  } else {
    hover_text = "NEW VERSION\n \nCheck Inventory\n \n" + update_msg;
    col = <1, 0, 0>;
    alpha = 1;
  }
  llSetText(hover_text, col, alpha);
}
showDialogPage(integer page) {
  string player_list = "";
  dialog_page = page;
  integer num_pages = (integer)(llGetListLength(nearby_players)/20) + 1;
  if (dialog_page > num_pages) {
    dialog_page = 1;
  } else if (dialog_page < 1) {
    dialog_page = num_pages;
  }

  dialog_listener = llListen(dialog_chan, "", owner, "");
  list dialog_buttons = [];
  if (dialog_page > 1) {
    dialog_buttons += ["⇐"];
  } else {
    dialog_buttons += [" "];
  }
  dialog_buttons += ["CLOSE"];

  integer num_buttons_this_page = 9;
  if (dialog_page < num_pages) {
    dialog_buttons += ["⇒"];
  } else {
    num_buttons_this_page = llGetListLength(nearby_players)/2 - (dialog_page - 1) * 9;
    dialog_buttons += [" "];
  }

  integer i;
  for(i=0;i<num_buttons_this_page;i++) {
    dialog_buttons += [(string)((dialog_page - 1) * 9 + i + 1)];
    player_list += (string)((dialog_page - 1) * 9 + i + 1) + ") " + llList2String(nearby_players, (dialog_page - 1) * 18 + i*2 + 1) + "\n";
  }

  llSetTimerEvent(60);
  llDialog(owner, "\n" + dialog_prompt + player_list, dialog_buttons, dialog_chan);
}
init() {
  string params = "action=r&uuid=" + (string)owner + "&hash=" + llSHA1String((string)owner + hash_seed);
  http_request_id = llHTTPRequest(API_URL,
                                  [
                                    HTTP_METHOD, "POST",
                                    HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                  ],
                                  params);
}

default {
  state_entry() {
    integer i;
    for (;i<llGetListLength(creators);i++) {
      creator_keys += [llList2Key(creators, i)];
    }
    owner = llGetOwner();
    is_ooc = FALSE;
    is_afk = FALSE;
    if (llGetRegionName() == allowed_region) {
      llAllowInventoryDrop(TRUE);
      is_current_version = TRUE;
      string obj_name = llGetObjectName();
      update_listener = llListen(update_chan, "", NULL_KEY, "");
      llSetTimerEvent(15);
      llRegionSay(update_chan, llGetSubString(obj_name, 14, llStringLength(obj_name) - 1));
      dialog_chan = (integer)llFrand(DEBUG_CHANNEL)*-1;
      currency_banked = -1;
      llSetText("", <1,1,1>, 1);
      init();
    } else {
      llOwnerSay("You are not in " + allowed_region + ". This HUD can only be used in " + allowed_region + ".");
      llRequestPermissions(owner, PERMISSION_ATTACH);
    }
  }
  touch_start(integer total_number) {
    if (llDetectedKey(0) == owner) {
      if (is_current_version) {
        if (dialog_listener) {
          llListenRemove(dialog_listener);
        }
        dialog_listener = llListen(dialog_chan, "", owner, "");
        string ooc_btn = "OOC On";
        if (is_ooc) {
          ooc_btn = "OOC Off";
        }
        string afk_btn = "AFK On";
        if (is_afk) {
          afk_btn = "AFK Off";
        }
        llDialog(owner,
                 "\n" + allowed_region + " HUD Menu\n \n" + CURRENCY_PREFIX + (string)currency_banked + CURRENCY_SUFFIX + "\n \n",
                 [
                   "Pay",
                   "Change",
                   "CLOSE",
                   "Attack",
                   ooc_btn,
                   afk_btn,
                   "Speaker"
                 ],
                 dialog_chan);
      } else {
        //Re-check versioning (crashes were interfering with checking, invalidating)
        llResetScript();
      }
    }
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id == http_request_id) {
      if (llSubStringIndex(body, "ERR,") == 0) {
        if (body == "ERR,Player with UUID Key of " + (string)owner + " not found.") {
          dialog_state = "character";
          dialog_listener = llListen(dialog_chan, "", owner, "");
          llSetTimerEvent(60);
          llTextBox(owner, "\nSetup Your Character\n \nWhat is your character's name?", dialog_chan);
        } else {
          llSay(0, "Error: " + llGetSubString(body, 4, llStringLength(body) - 1));
        }
      } else if (llSubStringIndex(body, "STAT,") == 0) {
        list fields = llCSV2List(llGetSubString(body, 5, llStringLength(body) - 1));
        character = llList2String(fields, 0);
        title = llList2String(fields, 1);
        currency_banked = llList2Integer(fields, 2);
        experience = llList2Integer(fields, 3);
        level = llList2Integer(fields, 14);
        xp_needed = llList2Integer(fields, 15);
        health = llList2Integer(fields, 4);
        attack = llList2Integer(fields, 5);
        defense = llList2Integer(fields, 6);
        boost_attack = llList2Integer(fields, 7);
        boost_defense = llList2Integer(fields, 8);
        attackable = llList2Integer(fields, 9) == 1;
        hover_color = <llList2Float(fields, 10), llList2Float(fields, 11), llList2Float(fields, 12)>;
        setTitle();
        if (llStringLength(llList2String(fields, 13)) > 0) {
          llRegionSayTo((key)llList2String(fields, 13), meter_chan, "1");
        }
        if (dialog_state == "saving_update") {
          llRegionSayTo(owner, meter_chan, "REFRESH");
          dialog_state = "";
        }
        llRegionSayTo(owner, meter_chan, "1");
        llListen(meter_chan, "", NULL_KEY, "");
        if (dialog_state == "pay now") {
          llSay(0, "Monies transferred.");
          dialog_state = "";
        }
      } else if (llSubStringIndex(body, "ATTACK,") == 0) {
        list fields = llCSV2List(llGetSubString(body, 7, llStringLength(body) - 1));
        llRegionSayTo(owner, 0, llList2String(fields, 0));
        llRegionSayTo(llList2Key(nearby_players, attack_person_idx), 0, llList2String(fields, 0));
        nearby_players = [];
        attack_person_idx = -1;
        init();
        llRegionSayTo(llList2Key(fields, 1), meter_chan, "1");
      } else {
        llSay(0, "Unexpected response: " + body);
      }
    }
  }
  listen(integer channel, string name, key id, string message) {
    if (channel == dialog_chan) {
      if (message == " " || message == "CLOSE") { return; }
      if (message == "⇐") {
        showDialogPage(dialog_page - 1);
      } else if (message == "⇒") {
        showDialogPage(dialog_page + 1);
      } else if (message == "OOC On") {
        is_ooc = TRUE;
        is_afk = FALSE;
        llRegionSayTo(owner, meter_chan, "OOC On");
        setTitle();
      } else if (message == "OOC Off") {
        is_ooc = FALSE;
        llRegionSayTo(owner, meter_chan, "OOC Off");
        setTitle();
      } else if (message == "AFK On") {
        is_afk = TRUE;
        is_ooc = FALSE;
        llRegionSayTo(owner, meter_chan, "AFK On");
        setTitle();
      } else if (message == "AFK Off") {
        is_afk = FALSE;
        llRegionSayTo(owner, meter_chan, "AFK Off");
        setTitle();
      } else if (message == "Speaker") {
        llRegionSayTo(owner, meter_chan, "Voice Chan17");
      } else if (message == "Pay") {
        scanning_for_payees = TRUE;
        nearby_players = [];
        pay_person_idx = -1;
        llSay(0, "Searching for players to pay.");
        llRegionSay(meter_chan, "Can Pay");
        llSetTimerEvent(5);
      } else if (message == "Change") {
        dialog_state = "character";
        dialog_listener = llListen(dialog_chan, "", owner, "");
        llSetTimerEvent(60);
        llTextBox(owner, "\nSetup Your Character\n \nWhat is your character's name?", dialog_chan);
      } else if (message == "Attack") {
        scanning_for_victims = TRUE;
        nearby_players = [];
        attack_person_idx = -1;
        llSay(0, "Searching for potential victims.");
        llRegionSay(meter_chan, "Can Attack");
        llSetTimerEvent(5);
      } else {
        if (dialog_state == "pay") {
          integer idx = (integer)message;
          if (idx > 0 && idx <= (llFloor(llGetListLength(nearby_players)/2) + 1)) {
            pay_person_idx = (idx - 1)*2;
            dialog_state = "pay now";
            llSetTimerEvent(60);
            llTextBox(owner, "\nPay Player\n \nEnter the amount to pay " + llList2String(nearby_players, pay_person_idx + 1) + ".", dialog_chan);
          } else {
            llOwnerSay("Please select a number from the list provided. Payment cancelled");
          }
        } else if (dialog_state == "attack") {
          attack_person_idx = ((integer)message - 1)*2;
          dialog_state = "attack type";
          dialog_listener = llListen(dialog_chan, "", owner, "");
          llSetTimerEvent(60);
          llDialog(owner, "\nAttack Player\n \nSelect the type of attack.", ["Pick Winner", "Win w/ Stats"], dialog_chan);
        } else if (dialog_state == "attack type") {
          attack_type = message;
          dialog_state = "";
          llSetTimerEvent(60);
          llSay(0, "Sending your attack request.");
          llRegionSayTo(llList2Key(nearby_players, attack_person_idx), meter_chan, "Attack Request," + (string)owner + "," + message);
        } else if (dialog_state == "attack confirm") {
          if (message == "Accept RP") {
            llRegionSayTo(requesting_attacker, meter_chan, "Attack Accept");
          } else {
            llRegionSayTo(requesting_attacker, meter_chan, "Attack Reject");
          }
        } else if (dialog_state == "pay now") {
          integer amt = (integer)message;
          if (amt > 0) {
            if (amt <= currency_banked) {
              string params = "uuid=" + (string)owner + "&hash=" + llSHA1String((string)owner + hash_seed)
                            + "&action=u"
                            + "&currency_banked=-" + (string)amt
                            + "&pass=" + llList2String(nearby_players, pay_person_idx);

              http_request_id = llHTTPRequest(API_URL,
                                              [
                                                HTTP_METHOD, "POST",
                                                HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                              ],
                                              params);
            } else {
              llOwnerSay("Payment cancelled. You cannot pay more than you have.");
            }
          } else {
            llOwnerSay("Payment cancelled. No amount entered.");
          }
        } else if (dialog_state == "character") {
          if (llStringLength(message) == 0) {
            message = "-";
          }
          character = message;
          dialog_state = "title";
          if (dialog_listener) {
            llListenRemove(dialog_listener);
          }
          dialog_listener = llListen(dialog_chan, "", owner, "");
          llSetTimerEvent(60);
          llTextBox(owner, "\nSetup Your Character\n \nWhat is your character's title (text under the character's name)?", dialog_chan);
        } else if (dialog_state == "title") {
          title = message;
          dialog_state = "hover_color";
          if (dialog_listener) {
            llListenRemove(dialog_listener);
          }
          dialog_listener = llListen(dialog_chan, "", owner, "");
          llSetTimerEvent(60);
          llTextBox(owner, "\nSetup Your Character\n \nWhat color would you like your hover text? (Use hex format. For example, FF9900)", dialog_chan);
        } else if (dialog_state == "hover_color") {
          if (dialog_listener) {
            llListenRemove(dialog_listener);
          }
          dialog_state = "saving_update";
          string params = "uuid=" + (string)owner + "&hash=" + llSHA1String((string)owner + hash_seed);

          if (currency_banked < 0) {
            params += "&action=c&user=" + llEscapeURL(llGetUsername(owner));
          } else {
            params += "&action=u";
          }
          params += "&name=" + llEscapeURL(character)
                  + "&title=" + llEscapeURL(title)
                  + "&hover_color=" + llEscapeURL(message);

          http_request_id = llHTTPRequest(API_URL,
                                          [
                                            HTTP_METHOD, "POST",
                                            HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                          ],
                                          params);
        }
      }
    } else if (channel == meter_chan) {
      list info = llGetObjectDetails(id, [OBJECT_CREATOR]);
      if (llListFindList(creator_keys, [llList2Key(info, 0)]) > -1) {
        if (message == "Can Pay") {
          llRegionSayTo(id, meter_chan, "Found Me," + (string)owner + "," + llGetDisplayName(owner));
        } else if (message == "Can Attack") {
          llRegionSayTo(id, meter_chan, "Found Me," + (string)owner + "," + llGetDisplayName(owner));
        } else if (message == "Ping") {
          llRegionSayTo(id, meter_chan, "Pong," + (string)owner);
        } else if (message == "1") {
          init();
        } else if (message == "Attack Accept") {
          string params = "uuid=" + (string)owner + "&hash=" + llSHA1String((string)owner + hash_seed)
                        + "&action=a"
                        + "&defender=" + llList2String(nearby_players, attack_person_idx)
                        + "&stats=" + llEscapeURL(attack_type);

          http_request_id = llHTTPRequest(API_URL,
                                          [
                                            HTTP_METHOD, "POST",
                                            HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                          ],
                                          params);
        } else if (message == "Attack Reject") {
          llSay(0, "The request to attack secondlife:///app/agent/" + llList2String(nearby_players, attack_person_idx) + "/about was rejected.");
        } else {
          list changes = llParseStringKeepNulls(message, [","], []);
          string action = llList2String(changes, 0);
          if (action == "STAT") {

            string params = "uuid=" + (string)owner + "&hash=" + llSHA1String((string)owner + hash_seed)
                          + "&action=u"
                          + "&experience=" + llList2String(changes, 1)
                          + "&health=" + llList2String(changes, 2)
                          + "&attack=" + llList2String(changes, 3)
                          + "&defense=" + llList2String(changes, 4)
                          + "&boost_attack=" + llList2String(changes, 5)
                          + "&boost_defense=" + llList2String(changes, 6)
                          + "&currency_banked=" + llList2String(changes, 7)
                          + "&pass=" + (string)id;

            http_request_id = llHTTPRequest(API_URL,
                                            [
                                              HTTP_METHOD, "POST",
                                              HTTP_MIMETYPE, "application/x-www-form-urlencoded"
                                            ],
                                            params);
          } else if (action == "Found Me") {
            nearby_players += [llList2Key(changes, 1), llList2String(changes, 2)];
          } else if (action == "Attack Request") {
            dialog_state = "attack confirm";
            dialog_listener = llListen(dialog_chan, "", owner, "");
            llSetTimerEvent(60);
            requesting_attacker = (key)llList2String(changes, 1);
            llDialog(owner, "\nIncoming Attack\n \nsecondlife:///app/agent/" + llList2String(changes, 1) + "/about has requested a " + llList2String(changes, 2) + " attack.", ["Accept RP", "Not RP"], dialog_chan);
          }
        }
      }
    } else if (channel == update_chan) {
      is_current_version = FALSE;
      update_msg = HUD_NAME + "\n" + message;
      setTitle();
    }
  }
  timer() {
    if (scanning_for_payees) {
      scanning_for_payees = FALSE;
      integer num_players = llGetListLength(nearby_players);
      if (num_players > 0) {
        integer i;
        dialog_prompt = "\n ** Select A Player To Pay **\n";
        dialog_state = "pay";
        showDialogPage(1);
        return;
      } else {
        llSay(0, "No one is nearby to pay.");
      }
    } else if (scanning_for_victims) {
      scanning_for_victims = FALSE;
      integer num_players = llGetListLength(nearby_players);
      if (num_players > 0) {
        integer i;
        dialog_prompt = "\n ** Select A Player To Attack **\n";
        dialog_state = "attack";
        showDialogPage(1);
        return;
      } else {
        dialog_state = "";
        llSay(0, "No one is nearby to attack.");
      }
    }
    if (dialog_listener) {
      nearby_players = [];
      pay_person_idx = -1;
      requesting_attacker = NULL_KEY;
      llListenRemove(dialog_listener);
    }
    if (update_listener) {
      llListenRemove(update_listener);
    }
  }
  run_time_permissions(integer perm) {
    if(perm & PERMISSION_ATTACH) {
      if (llGetRegionName() != allowed_region) {
        llDetachFromAvatar();
      }
    }
  }
  attach(key id) {
    if (id) {
      llResetScript();
    }
  }
  changed(integer change) {
    if (change & CHANGED_REGION) {
      if (llGetRegionName() != allowed_region) {
        llOwnerSay("You are not in " + allowed_region + ". This HUD can only be used in " + allowed_region + ".");
        llRequestPermissions(owner, PERMISSION_ATTACH);
      }
    }
  }
}
