# Secondlife Roleplay HUD

This HUD was designed to facilitate and augment roleplay. It supports a currency, loot drops, crafting machines, daily pay, an optional titler, and, of course, a HUD.

Initially built to provide a HUD without in-game mechanics for the Helix City roleplay sim, it is being made available for everyone to use however they want. The only rights on this code is the right for everyone to use what is here on this repo so long as it doesn't infringe on this right.

One of the things I noted with some roleplay systems is the lack of security. In the event of a MITM attack, the server would be wide open for manipulation. This system employs a hashing seed to provide a bit of security. Should your seed ever be compromised, you should change it immediately.

I hope you enjoy your RP.

Sylas

# Compiling the code

The code has been built using the [Firestorm LSL Preprocessor directives](https://wiki.firestormviewer.org/fs_preprocessor). This way you can edit the [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl) file to apply the necessary global settings.

NOTE: These are _not_the only settings you need to adjust. Many are per-file, so be sure to look at the source code to edit custom messages and other settings as described below.

# How to Configure Your RP HUD System

There are 4 main tasks to setting up your system:
1. Configure the database & server-side script
1. The Admin HUD
1. The Player HUD & Titler
1. The looting system

You can also add daily check in benefits and questing.

Be sure you have configured [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl) before proceeding.

## Configure the database & server-side script

- [ ] _Documenting this and providing the code will come soon._

## The Admin HUD

Script: [sl-rp-admin-hud-controller](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-admin-hud-controller)

Place the script in any object and attach as a HUD. Click to operate.

## The Player HUD & Titler
### Player HUD

Script: [sl-rp-player-hud](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-player-hud)

Stats are displayed as floating text. Place the script in any object set as a HUD attachment point.

Change `default_texture` to a UUID or texture in the inventory of the object which represents the default texture to display when the HUD is current. When out of date, this texture will be switched to white. It has been observed that in some cases a false-positive happens, changing the HUD to white. End users can click the HUD and it will re-validate the version.

No other configuration is necessary.

- [ ] Issue: M$ is set as the label for currency. Needs to be put into [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl). If you need to change this before [@SylasSeabrook](https://github.com/SylasSeabrook) gets to it, edit lines 48 and 152.

### Player Titler

Script: [sl-rp-player-titler](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-player-titler)

The Player Titler requires no additional configuration. Just put in an object and set the attachment point.

## The Looting System

The looting system is comprised of 4 different items:
1. Items used for crafting
1. Items usable by players
1. Loot drops
1. Crafting machines

### Items Used For Crafting

Script: N/A

These are just objects whose root object is created by you. The system checks against the `CREATORS` list as a control. They have no other functionality and there is not a script for them.

### Items Usable By Players

Script: [sl-rp-consumable-item](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-consumable-item)

Experience, health, attack, defense, attack boost, defense boost, and currency can be affected (one or more at the same time) by a usable item. _Attack boost and defense boost are currently placeholders and are not functional._ To set the values for each item which can be consumed, change the value in double quotes at the top of the file. Negative numbers cause harm.

Usable items can be attached or they can be rezzed. Rezzed usable items can be used by anyone within 5 meters (for sharing or stealing).

When a usable item is used, it knows it has been used because it sends the command to apply changes to the HUD which then verifies that the change completed and responds to the item with a confirmation. At that point, the item's texture is changed to a red/trans stripe and the script itself is deleted. If you wish to change the texture for a used item, edit the `used_texture_uuid` variable at the top of the file.

### Loot Drops

Script: [sl-rp-loot-drop](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-loot-drop)

You *must* configure each of these variables:
* `machine_name` -- This is the name of the crafting machine. It will be logged in the database.
* `droppables` -- See below for a discussion of this variable.
* `max_distance_from_object` -- How close in meters the player must be to interact with the object
* `min_level` -- The minimum level a player must have in order to interact with the object
* `cooldown_seconds` -- The average time inbetween receiving a drop for each player
* `cooldown_seconds_variation_percent` -- A number, expressed as a decimal, representing the range as a percent of the cooldown time used for each time inbetween receiving a drop. See below for details.
* `success_msg`
* `damage_msg`
* `health_damage_probability_percent` -- The percent expressed as a whole number between 0 and 100 which will result in the player receiving health damage for interacting with the loot drop. They will also receive the item.
* `health_damage_amount` -- How much health will be impacted if this time dropping loot is selected to damage health.
* `xp_penalty_probability_percent` -- The percent expressed as a whole number between 0 and 100 which will result in the player receiving experience damage for interacting with the loot drop. The will also receive the item.
* `xp_penalty_amount` -- How much experience will be impacted if this time dropping loot is selected to damage experience.

#### The `droppables` variable

The format of the `droppables` variable is a stride lists where each stride is of the format "_ITEM_NAME_", (integer)relative_weight.  For example, if we have `apple`, `banana`, and `orange`, the list might look like this:

    list droppables = ["apple", 1,
                       "banana", 2,
                       "orange" 3
                      ];

The relative weights determine how likely each item is to be selected. In the example above, the sum of the relative weights is 6. That means 1/6 (16.67%) chance of getting an apple, 2/6 = 1/3 (33.33%) chance of getting a banana, 3/6 = 1/2 (50%) chance of getting an orange. The numbers must be integers and can be larger.

#### Cooldowns

Cooldowns operate so that they apply to each player, not the loot drop itself. When a player gets a drop, a time delay is calculated and sent to the server. It is this delay which is used before the player can receive an item from this loot drop again.  For example, if the cooldown is 3600 (1 hour) and the `cooldown_seconds_variation_percent` is .25, then the time selected will 1 hour +/- 15 minutes (.25 * 1 hr); that is, 45 minutes to 1 hour 15 minutes. This feature was added to prevent hoppers from hopping over, collecting, leaving. Stay and roleplay!

As an additional note, on the server-side you are able to set the maximum number of drops per player for a 24 hour rolling window. That will be discussed when that script is uploaded.

### Crafting Machines

A crafting machine takes one or more items (drops or usable items) in various quantities, delivers a different item, then deletes the items. This system is setup to allow a crafting machine to deliver one of two objects which are labeled the good object and the critical failure object (my fancy word for saying bad). Each crafting machine must be made of 2 prims with the root prim containing the good object and the [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine) script. One (and only one) of the linked prims must contain a critical failure object (If you don't want those, lie and put the good object in it too) and the script [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure).

#### The Crafting Machine

The root object of the crafting machine must contain the [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine) script with these variables configured:

* `machine_name` -- the name of the crafting machine. It should match what is put in [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure)
* `ingredients` -- Strided list of the format `"_ITEM_NAME_", (integer)qty_required, 0` (Comment: The last 0 is used as a placeholder when counting players' dropped items)
* `produced_item` -- The name of the object in inventory which will be given when the required number of each ingredient is in the device and the player clicks it. MUST match what is set in [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure)
* `min_level` -- The minimum required player level to use this crafting machine
* `failure_message`
* `success_rate` -- The percentage as a whole number where the desired item is given to the player.
* `crit_fail_rate` -- When the success rate does not indicate this player to get the desired item, they will get nothing, lose all of their items, and receive the `failure_message` message. However, from that group, some will get a bad item. The `crit_fail_rate` is the percentage as a whole number of those who do not fall in the success rate who will receive the critical failure object (the bad one).
* `crit_fail_rate_damping_by_level_above_min_level` For each level above `min_level`, this number is subtracted from `crit_fail_rate` (never going below zero). This means that higher level players will have the same chance of success or fail, but less of a chance of getting a bad item.

- [ ] There are currently a few lines which are used for the animation on the Helix City crafting machines, noted in the source code. Undoubtedly they won't be useful to anyone else.

#### The Critical Failure Linked Prim (Bad object)

You must configure the machine name for logging purposes. It should match what you set in [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine). The object *must* be the same name as the `produced_item` from the [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine) script.

No additional configuration is needed.

## Daily Checkin

Script: [sl-rp-daily-checkin](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-daily-checkin)

Set the `machine_name` in the file for logging purposes. No additional configuration is needed.

## Questing

The scripts provided give you all you really need for quests, but you will need to be a scripter to understand how. I don't currently plan on putting these out there, but if there are generalized ones people are willing to contribute, awesome!
