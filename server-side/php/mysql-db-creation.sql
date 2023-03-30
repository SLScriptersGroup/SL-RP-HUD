CREATE DATABASE `sl_rp_hud` DEFAULT CHARACTER SET utf8mb4;

CREATE TABLE `player` (
  `player_id` int(11) NOT NULL AUTO_INCREMENT,
  `username_sl` varchar(64) NOT NULL,
  `uuid_sl` varchar(36) NOT NULL,
  `name_character` varchar(64) DEFAULT NULL,
  `title` varchar(64) DEFAULT NULL,
  `currency_banked` int(11) NOT NULL DEFAULT '1000',
  `currency_bonus` decimal(3,2) unsigned DEFAULT '0.00',
  `experience` int(10) unsigned NOT NULL DEFAULT '1',
  `health` tinyint(3) unsigned NOT NULL DEFAULT '10',
  `attack` tinyint(3) unsigned NOT NULL DEFAULT '5',
  `defense` tinyint(3) unsigned NOT NULL DEFAULT '5',
  `boost_attack` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `boost_defense` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `instant_last_defense` datetime DEFAULT NULL,
  `instant_created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `instant_last_stat_auto_update` datetime DEFAULT NULL,
  `hover_color` char(32) DEFAULT '1,1,1',
  `lvl` tinyint(3) unsigned DEFAULT '1',
  `day_last_worked` date DEFAULT NULL,
  `total_days_worked` int(10) unsigned DEFAULT '0',
  PRIMARY KEY (`player_id`),
  UNIQUE KEY `username_sl_UNIQUE` (`username_sl`),
  UNIQUE KEY `uuid_sl` (`uuid_sl`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `player_action` (
  `player_action_id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `quest_action` varchar(36) NOT NULL,
  `instant_completed` datetime DEFAULT NULL,
  PRIMARY KEY (`player_action_id`),
  UNIQUE KEY `player_action_UNIQUE` (`player_id`,`quest_action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `player_log` (
  `player_log_id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) unsigned NOT NULL,
  `instant` datetime NOT NULL,
  `source_name` varchar(64) DEFAULT NULL,
  `currency_banked` int(11) DEFAULT NULL,
  `experience` int(10) DEFAULT NULL,
  `health` tinyint(3) DEFAULT NULL,
  `attack` tinyint(3) DEFAULT NULL,
  `defense` tinyint(3) DEFAULT NULL,
  `boost_attack` tinyint(3) DEFAULT NULL,
  `boost_defense` tinyint(3) DEFAULT NULL,
  PRIMARY KEY (`player_log_id`),
  KEY `player_id` (`player_id`),
  KEY `instant` (`instant`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE `player_to_item` (
  `player_to_item_id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL,
  `source` varchar(128) NOT NULL,
  `item` varchar(128) NOT NULL,
  `instant_created` datetime DEFAULT NULL,
  `instant_cooldown_expires` datetime DEFAULT NULL,
  `is_crit_fail` enum('No','Yes') NOT NULL DEFAULT 'No',
  PRIMARY KEY (`player_to_item_id`),
  KEY `player` (`player_id`),
  KEY `source` (`source`),
  KEY `instant_created` (`instant_created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
