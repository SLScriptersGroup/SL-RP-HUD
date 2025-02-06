# Secondlife Roleplay HUD

This HUD was designed to facilitate and augment roleplay. It supports a currency, loot drops, crafting machines, daily pay, an optional titler, and, of course, a HUD.

Initially built to provide a HUD without in-game mechanics for a now-defunct roleplay sim, it is being made available for everyone to use however they want. The only rights on this code is the right for everyone to use what is here on this repo so long as it doesn't infringe on this right.

This system employs a hash seed to mitigate MITM attacks. Should your seed ever be compromised, you should change it immediately.

I hope you enjoy your RP.

Sylas

# Compiling the code

The code uses [Firestorm LSL Preprocessor directives](https://wiki.firestormviewer.org/fs_preprocessor). Edit global settings in [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl).

NOTE: These are _not_ the only settings you need to adjust. Check source code for per-file settings.

# How to Setup Your RP HUD System

Setup steps:
1. **[REQUIRED]** [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl)
1. **[REQUIRED]** Database & server-side configuration
1. Create Admin HUD
1. Create Player HUD & Titler
1. Setup looting system
1. Setup daily check-in
1. Create quests

## Database & server-side script

1. Create a MySQL database with tables for the HUD using [mysql-db-creation.sql](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/server-side/mysql-db-creation.sql).
1. Assign a database user.
1. Update the connection details in [api.php](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/server-side/api.php).
1. Populate the `$hash_seed` variable with a random string to be used to help secure your system. It is also the value in quotes in the [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl) file -- they **must** match.
1. Set the correct defaults for [Player.php](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/server-side/classes/Player.php) class constants.

## The Admin HUD

Script: [sl-rp-admin-hud-controller](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-admin-hud-controller.lsl)

This script works by including in any object which attaches as a HUD. When the object is clicked, the menu will be displayed.

## The Player HUD & Titler
### Player HUD

Script: [sl-rp-player-hud](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-player-hud.lsl)

Stats are displayed as hover text on an object containing the script with a HUD attachment point.

Change `default_texture` to a UUID or the name of a texture in the inventory of the object which represents the texture to display for the current version of the HUD. When out of date, this texture will be switched to white. In some cases the current version broadcast is incorrectly received causing the HUD to white. End users can click the HUD to re-validate the version.

### Player Titler

Script: [sl-rp-player-titler](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-player-titler.lsl)

Just put Player Titler an object and set the attachment point. The Player Titler has no configuration options.

## The Looting System

The looting system is comprised of 4 different items:
1. Crafting items
1. Usable items
1. Loot drops
1. Crafting machines

### Crafting Items

Script: N/A

Crafting items are items used by crafting machines _and_ created by someone in the [config.lsl](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/config.lsl)'s `CREATORS` list.

### Usable Items

Script: [sl-rp-consumable-item](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-consumable-item.lsl)

Experience, health, attack, defense, attack boost, defense boost, and currency can be affected (one or more at the same time) by a usable item. **Attack boost and defense boost are currently placeholders and are not functional.** Adjust the variable value in double quotes at the top of the file. Positive numbers increase stats, negative numbers decreate stats. Levels are increased automatically if experience is increased or decreased.

Usable items can be attached or they can be rezzed. Rezzed usable items can be used by anyone within 5 meters (for sharing, stealing, or bonus drops).

When a usable item is clicked, it sends the stat changes to the HUD. The HUD sends the changes to the server, verifies that the change was successful, and sends the item a success confirmation. When a success confirmation is received, the item's texture is changed to the value of `used_texture_uuid` (default is a red/trans stripe texture) and the script itself is deleted. If a response is not received in 15 seconds, a message is sent to the player.

### Loot Drops

Script: [sl-rp-loot-drop](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-loot-drop.lsl)

You *must* configure each of these variables:
* `machine_name` -- The name of the crafting machine logged in the database.
* `droppables` -- See [The `droppables` variable](#user-content-the-droppables-variable)
* `max_distance_from_object` -- The player must be closer than this number of meters from the object.
* `min_level` -- The player's minimum level to use this item.
* `cooldown_seconds` -- The average time players must wait before using this item.
* `cooldown_seconds_variation_percent` -- The decimal form percentage of `cooldown_seconds` defining the min and max time players must wait before using this item. See [The `droppables` variable](#user-content-the-droppables-variable) for details.
* `success_msg`
* `damage_msg`
* `health_damage_probability_percent` -- The chance (percentage 0 to 100 as an integer) of a player losing health when using the loot drop in addition to receiving the item.
* `health_damage_amount` -- The amount of health to subtract based on `health_damage_probability_percent`.
* `xp_penalty_probability_percent` -- The chance (percentage 0 to 100 as an integer) of a player losing experience when using the loot drop in addition to receiving the item.
* `xp_penalty_amount` -- The amount of experience to subtract based on `xp_penalty_probability_percent`.

#### The `droppables` variable

`droppables` is a strided list of the format `"_ITEM_NAME_", (integer)relative_weight`.  For example, if we have `apple`, `banana`, and `orange`, the list might look like this:

    list droppables = ["apple", 1,
                       "banana", 2,
                       "orange" 3
                      ];

The relative weights determine how likely each item is to be selected. In the example above, the sum of the relative weights is 6. That means a 1/6 (16.67%) chance of getting an apple, a 2/6 = 1/3 (33.33%) chance of getting a banana, and a 3/6 = 1/2 (50%) chance of getting an orange. The numbers must be integers and can be larger.

#### Cooldowns

Cooldowns apply to each player. When a player receives a loot drop item, a time delay is calculated and sent to the server. The player can receive another item from this loot drop after the delay.  For example, if the `cooldown_seconds` is 3600 (1 hour) and the `cooldown_seconds_variation_percent` is .25, then the time selected will be 45 minutes to 1 hour 15 minutes, 1 hour ± 15 minutes (.25 * 1 hr). This promotes roleplayers remaining on the sim.

[`DROPS_PER_24_HOURS`](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/server-side/classes/Player.php) sets the maximum number of drops per player for a 24 hour rolling window.

### Crafting Machines

Crafting machines have a recipe requiring one or more crafting or usable items, then delivers a different crafting or usable item, deleting the items used in the recipe.

One of two objects are delivered. Each crafting machine must be made of 2 prims: (1) The root prim containing the good object and the [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine.lsl) script and (2) a linked prim containing a critical failure object and the script [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure.lsl).

#### The Crafting Machine

The root object of the crafting machine must contain the [sl-rp-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine.lsl) script with these variables configured:

* `machine_name` -- The name of the crafting machine used in both the root object and the linked object containing [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure.lsl).
* `ingredients` -- Strided list of the format `"_ITEM_NAME_", (integer)qty_required, 0` (The last 0 is used as a placeholder when counting players' dropped items.)
* `produced_item` -- The name of the inventory object (Content tab) given when all required recipe items added to the Content tab in both the root object and the linked object with the [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure.lsl) script.
* `min_level` -- The minimum required player level to use this crafting machine.
* `failure_message`
* `success_rate` -- The percentage (an integer between 0 and 100) likelihood of the `produced_item` in the root object being given. If `success_rate` does not result in the `produced_item` in the root object being given, all required recipe items added to the Content tab are deleted and the `failure_message` message is sent to the player.
* `crit_fail_rate` -- The percentage (an integer between 0 and 100) of those who received the `failure_message` message who will receive the item in the linked object containing the [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure.lsl) script.
* `crit_fail_rate_damping_by_level_above_min_level` For each level above `min_level`, this number is subtracted from `crit_fail_rate` (never going below zero).

#### The Critical Failure Linked Prim (Bad object)

The linked object containing the [sl-rp-crafting-machine-crit-failure](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-crafting-machine-crit-failure.lsl) script object *must* be the same name as the `produced_item`.

#### Random Produced Item
The [sl-rp-random-crafting-machine](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-random-crafting-machine.lsl) is used to generate a random item from a single set of ingredients. Items are chosen with a weighted frequency, so the product_items list is of the form `"item name", frequency` where the frequency can be a percentage *if all frequencies sum to 100* or a weight. For example, in this configuration there is a 1/3 chance of getting a thingy and a 2/3 chance of getting a widget:

```
list product_items = [
  "thingy", 5,
  "widget", 10
];
```

This script does not employ the critical failure rate because that does not support multiple items.

## Daily Checkin

Script: [sl-rp-daily-checkin](https://github.com/SLScriptersGroup/SL-RP-HUD/blob/master/sl-rp-daily-checkin.lsl)

`machine_name` is used for logging.

## Questing

The scripts provided give you all you really need for quests, but you will need to be a scripter to understand how. I don't currently plan on putting these out there, but if there are generalized ones people are willing to contribute, awesome!
