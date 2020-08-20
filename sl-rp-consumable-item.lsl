#include "config.lsl"
//Note that this specifically does NOT check for owner. People can steal other people's stuff (so smart to add instead of rezz). This allows sharing as well.
string used_message = "I'm all used up!";
string used_texture_uuid = "69c2c03f-a56b-b91e-91a6-2b37cb6c849b";
string experience = "0";
string health = "0";
string attack = "0";
string defense = "0";
string boost_attack = "0";
string boost_defense = "0";
string currency_banked = "0";
integer meter_chan = METER_CHAN;
integer meter_listener;
key toucher = NULL_KEY;
default {
    touch_start(integer total_number) {
      if (llVecDist(llGetPos(), llDetectedPos(0)) > 5) {
        llRegionSayTo(llDetectedKey(0), 0, "Must be closer to use this.");
        return;
      }
      toucher = llDetectedKey(0);
      llRegionSayTo(toucher,
                    meter_chan,
                      "STAT"
                    + "," + experience
                    + "," + health
                    + "," + attack
                    + "," + defense
                    + "," + boost_attack
                    + "," + boost_defense
                    + "," + currency_banked
                   );
      llSetTimerEvent(15);
      meter_listener = llListen(meter_chan, "", NULL_KEY, "");
    }
    
    listen(integer channel, string name, key id, string message) {
      if (channel == meter_chan) {
        if (message == "1") {
          llSetTimerEvent(0);
          llListenRemove(meter_listener);
          if (toucher == NULL_KEY) {
            llSay(0, used_message);
          } else {
            llRegionSayTo(toucher, 0, used_message);
          }
          llSetLinkTexture(LINK_SET, used_texture_uuid, ALL_SIDES);
          llRemoveInventory(llGetScriptName());
          if (llGetAttached() == 0) {
            llDie();
          }
        }
      }
    }
    timer() {
      llSetTimerEvent(0);
      if (toucher == NULL_KEY) {
        llSay(0, "Your HUD did not respond in time.");
      } else {
        llRegionSayTo(toucher, 0, "Your HUD did not respond in time.");
      }
      toucher = NULL_KEY;
      llListenRemove(meter_listener);
    }
}
