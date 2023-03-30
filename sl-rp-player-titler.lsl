#include "config.lsl"
string allowed_region = ALLOWED_REGION;
string hash_seed = HASH_SEED;
key http_request_id;
string character;
string title;
vector hover_color;
integer is_ooc;
integer is_afk;
integer meter_chan = METER_CHAN;
key owner;
integer char_voice_listener;
integer char_voice_chan;

setTitle() {
  string hover_text = character + "\n";
  if (llStringLength(title) > 0) {
    hover_text += title;
  }
  if (is_ooc) {
    hover_text += "\n(( OOC ))";
  } else if (is_afk) {
    hover_text += "\n(( AFK ))";
  }

  llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_COLOR, ALL_SIDES, hover_color, 1]);
  llSetText(hover_text, hover_color, 1);
  updateCharVoice();
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
updateCharVoice() {
  string name = llGetObjectName();
  if (name != TITLER_NAME) {
    char_voice_chan = (integer)llGetObjectDesc();
    if (char_voice_chan > 0) {
      char_voice_listener = llListen(char_voice_chan, "", owner, "");
    }
  } else if (char_voice_listener) {
    llListenRemove(char_voice_listener);
  }
}
default {
  state_entry() {
    owner = llGetOwner();
    if (llGetRegionName() == allowed_region) {
      is_ooc = FALSE;
      is_afk = FALSE;
      llListen(meter_chan, "", NULL_KEY, "");
      llSetText("", <1,1,1>, 1);
      init();
    } else {
      llOwnerSay("You are not in " + allowed_region + ". This titler can only be used in " + allowed_region + ".");
      llRequestPermissions(owner, PERMISSION_ATTACH);
    }
  }
  attach(key id) {
    if (id) {
      llSetObjectName(TITLER_NAME);
      llResetScript();
    }
  }
  http_response(key request_id, integer status, list metadata, string body) {
    if (request_id == http_request_id) {
      if (llSubStringIndex(body, "STAT,") == 0) {
        list fields = llCSV2List(llGetSubString(body, 5, llStringLength(body) - 1));
        character = llList2String(fields, 0);
        title = llList2String(fields, 1);
        hover_color = <llList2Float(fields, 10), llList2Float(fields, 11), llList2Float(fields, 12)>;
        if (char_voice_chan > 0) {
          llSetObjectName(character);
        }
        setTitle();
      }
    }
  }
  listen(integer channel, string name, key id, string message) {
    if (channel == meter_chan) {
      list info = llGetObjectDetails(id, [OBJECT_CREATOR, OBJECT_OWNER]);
      if (llList2Key(info, 1) == owner) {
        if (message == "OOC On") {
          is_ooc = TRUE;
          is_afk = FALSE;
          setTitle();
        } else if (message == "OOC Off") {
          is_ooc = FALSE;
          setTitle();
        } else if (message == "AFK On") {
          is_afk = TRUE;
          is_ooc = FALSE;
          setTitle();
        } else if (message == "AFK Off") {
          is_afk = FALSE;
          setTitle();
        } else if (message == "REFRESH") {
          init();
        } else if (llSubStringIndex(message, "Voice Chan") == 0) {
          char_voice_chan = (integer)llGetSubString(message, 10, llStringLength(message) - 1);
          llSetObjectDesc((string)char_voice_chan);
          string name = llGetObjectName();
          if (name == TITLER_NAME) {
            llOwnerSay("Enabling character voice on channel " + (string)char_voice_chan);
            llSetObjectName(character);
          } else {
            llOwnerSay("Disabling character voice.");
            llSetObjectName(TITLER_NAME);
          }
          setTitle();
        }
      }
    } else if (channel == char_voice_chan) {
      llSay(0, message);
    }
  }
  run_time_permissions(integer perm) {
    if(perm & PERMISSION_ATTACH) {
      if (llGetRegionName() != allowed_region) {
        llDetachFromAvatar();
      }
    }
  }
  changed(integer change) {
    if (change & CHANGED_REGION) {
      if (llGetRegionName() != allowed_region) {
        llOwnerSay("You are not in " + allowed_region + ". This titler can only be used in " + allowed_region + ".");
        llRequestPermissions(owner, PERMISSION_ATTACH);
      }
    }
  }
}
