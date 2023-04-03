class Player {
  static MAX_HEALTH = 10;
  static MAX_ATTACK = 10;
  static MAX_DEFENSE = 10;
  static DROPS_PER_24_HOURS = 8;
  static FIGHT_WINNER_EXPERIENCE = 2;
  static FIGHT_LOSER_EXPERIENCE = 1;
  static FIGHT_LOSER_HEALTH = -1;
  static CHECK_IN_NUM_DAYS_FOR_BONUS = 5;
  static CHECK_IN_XP_BONUS = 1;

  static INTEGER_CHARACTERISTICS = {'currency_banked':'currency_banked',
                                    'experience':'experience',
                                    'attack':'attack',
                                    'defense':'defense',
                                    'boost_attack':'boost_attack',
                                    'boost_defense':'boost_defense'
                                  };
  #_player_id = 0;
  #_username_sl = '';
  #_uuid_sl = '';
  #_name_character = '';
  #_title = '';
  #_currency_banked = 0;
  #_currency_bonus = 0;
  #_experience = 0;
  #_health = 0;
  #_attack = 0;
  #_defense = 0;
  #_boost_attack = 0;
  #_boost_defense = 0;
  #_instant_last_defense = '';
  #_instant_created = '';
  #_instant_last_stat_auto_update = '';
  #_hover_color = '';
  #_lvl = 0;
  #_day_last_worked = '';
  #_total_days_worked = 0;

  #_player_paid;
  constructor() {
  }
  
  Update(update_fields = false) {
  
  }
  Work() {
  
  }
  Attack() {

  }
  Create() {

  }
  Read() {

  }
  _placeBattle($attacker, $defender) {

  }
  _experienceToLevel($xp) {

  }
}
module.exports = Player;