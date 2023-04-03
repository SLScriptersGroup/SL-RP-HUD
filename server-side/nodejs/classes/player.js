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
  
  constructor() {}
  
  Update(update_fields = false) {
    this.Read();
  }
  Work() {
    this.Read();
  }
  Attack() {
    this.Read();
  }
  Create() {

  }
  Read() {
    //global.http.body
  }
  _placeBattle($attacker, $defender) {

  }
  _experienceToLevel($xp) {

  }

  set player_id(val) {
    this.#_player_id = parseInt(val);
  }
  set username_sl(val) {
    this.#_username_sl = val.replace(/[^a-z0-9]/ig, '');
  }
  set uuid_sl(val) {
    this.#_uuid_sl = val.replace(/[^a-z0-9]/ig, '');
  }
  set name(val) {
    this.#_name_character = val.replace(/[,]/g, '');
  }
  set title(val) {
    this.#_title = val.replace(/[,]/g, '');
  }
  set currency_banked(val) {
    this.#_currency_banked += parseInt(val);
  }
  set currency_bonus(val) {
    this.#_currency_bonus += parseInt(val);
  }
  set experience(val) {
    this.#_experience += parseInt(val);
    let xp = this._experienceToLevel(this.#_experience);
    this.#_lvl = xp.level;
  }
  set health(val) {
    this.#_health += parseInt(val);
    if (this.#_health > Player.MAX_HEALTH) {
      this.#_health = Player.MAX_HEALTH;
    } else if (this.#_health < 0) {
      this.#_health = 0;
    }
  }
  set attack(val) {
    this.#_attack += parseInt(val);
    if (this.#_attack > Player.MAX_ATTACK) {
      this.#_attack = Player.MAX_ATTACK;
    } else if (this.#_attack < 0) {
      this.#_attack = 0;
    }
  }
  set defense(val) {
    this.#_defense += parseInt(val);
    if (this.#_defense > Player.MAX_DEFENSE) {
      this.#_defense = Player.MAX_DEFENSE;
    } else if (this.#_defense < 0) {
      this.#_defense = 0;
    }
  }
  set boost_attack(val) {
    this.#_boost_attack += parseInt(val);
    if (this.#_this.boost_attack > Player.MAX_ATTACK) {
      this.#_this.boost_attack = Player.MAX_ATTACK;
    } else if (this.#_this.boost_attack <  0) {
      this.#_this.boost_attack = 0;
    }
  }
  set boost_defense(val) {
    this.#_boost_defense += parseInt(val);
    if (this.#_boost_defense > Player.MAX_DEFENSE) {
      this.#_boost_defense = Player.MAX_DEFENSE;
    } else if (this.#_boost_defense < 0) {
      this.#_boost_defense = 0;
    }
  }
  set instant_last_defense(val) {
    let d = new Date(val);
    if (!isNaN(d)) {
      this.#_instant_last_defense = d.getFullYear() + '-' + (d.getMonth() + 1<10?'0':'') + (d.getMonth() + 1) + '-' + (d.getDate() < 10?'0':'') + d.getDate()
                                  + ' ' + (d.getHours() < 10?'0':'') + d.getHours() + ':' + (d.getMinutes() < 10?'0':'') + d.getMinutes() + ':' + (d.getSeconds() < 10?'0':'') + d.getSeconds();
    } else {
      this.#_instant_last_defense = '';
    }
  }
  set instant_created(val) {
    let d = new Date(val);
    if (!isNaN(d)) {
      this.#_instant_created = d.getFullYear() + '-' + (d.getMonth() + 1<10?'0':'') + (d.getMonth() + 1) + '-' + (d.getDate() < 10?'0':'') + d.getDate()
                                  + ' ' + (d.getHours() < 10?'0':'') + d.getHours() + ':' + (d.getMinutes() < 10?'0':'') + d.getMinutes() + ':' + (d.getSeconds() < 10?'0':'') + d.getSeconds();
    } else {
      this.#_instant_created = '';
    }
  }
  set instant_last_stat_auto_update(val) {
    let d = new Date(val);
    if (!isNaN(d)) {
      this.#_instant_last_stat_auto_update = d.getFullYear() + '-' + (d.getMonth() + 1<10?'0':'') + (d.getMonth() + 1) + '-' + (d.getDate() < 10?'0':'') + d.getDate()
                                  + ' ' + (d.getHours() < 10?'0':'') + d.getHours() + ':' + (d.getMinutes() < 10?'0':'') + d.getMinutes() + ':' + (d.getSeconds() < 10?'0':'') + d.getSeconds();
    } else {
      this.#_instant_last_stat_auto_update = '';
    }
  }
  set hover_color(val) {
    this.#_hover_color = val.toUpperCase().replace(/[^A-F0-9]/gi, '');
    if (this.#_hover_color.length == 6) {
      this.#_hover_color = String(parseInt(this.#_hover_color.substring(0,1), 16)/255).substring(0, 7) + ','
                         + String(parseInt(this.#_hover_color.substring(2,3), 16)/255).substring(0, 7) + ','
                         + String(parseInt(this.#_hover_color.substring(4,5), 16)/255).substring(0, 7);
    } else {
      this.#_hover_color = val.replace(/[^0-9,\.]/gi, '');
      let s = this.#_hover_color.split(',');
      if (s.length != 3) {
        this.#_hover_color = '1,1,1';
      }
    }
    this.#_hover_color = this.#_hover_color.replace(/[<> ]/g, '');
  }
  set day_last_worked(val) {
    this.#_day_last_worked = new Date(val);
    if (isNaN(this.#_day_last_worked)) {
      this.#_day_last_worked = '';
    } else {
      this.#_day_last_worked = this.#_day_last_worked.getFullYear() + '-' + (this.#_day_last_worked.getMonth() + 1<10?'0':'') + (this.#_day_last_worked.getMonth() + 1) + '-' + (this.#_day_last_worked.getDate() < 10?'0':'') + this.#_day_last_worked.getDate();
    }
  }
  set total_days_worked(val) {
    this.#_total_days_worked += parseInt(val);
  }
  toString() {
    let level_info = this._experienceToLevel(this._experience);
    let response = 'STAT,'
              + this._name_character + ','
              + this._title + ','
              + this._currency_banked + ','
              + level_info['xp'] + ','
              + this._health + ','
              + this._attack + ','
              + this._defense + ','
              + this._boost_attack + ','
              + this._boost_defense + ','
              + parseInt(   this._instant_last_defense.length == 0
                         || ((new Date(this._instant_last_defense)).getTime() + 60*60*1000 > Date.now())
                        ) + ',' //Not implemented client side
              + this._hover_color + ',';
    if (typeof(global.http.body.pass) != 'undefined') {
      response += global.http.body.pass;
    }
    response += ',' + level_info.level
              + ',' + level_info.xp_needed;
    if (parseInt(this._player_paid) > 0) {
      response += ',' + parseInt(this._player_paid);
    }
    return response;
  }
}
module.exports = Player;