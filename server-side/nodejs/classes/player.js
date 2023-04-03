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

  static INTEGER_CHARACTERISTICS = ['currency_banked',
                                    'experience',
                                    'attack',
                                    'defense',
                                    'boost_attack',
                                    'boost_defense'
                                  ];
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
  
  async Update(update_fields = false) {
    this.Read();
    if (update_fields === false) {
      update_fields = global.http.body;
    }
    try {
      let updates = {};
      if (typeof update_fields.name != 'undefined') {
        this.name_character = update_fields.name;
      }
      if (typeof update_fields.title != 'undefined') {
        this.title = update_fields.title;
      }
      if (typeof update_fields.hover_color != 'undefined' && update_fields.hover_color.length > 0) {
        this.hover_color = update_fields.hover_color;
      }
      if (typeof update_fields.health != 'undefined' && update_fields.health.length > 0) {
        updates.health = update_fields.health;
        this.health = update_fields.health;
      }
      if (typeof update_fields.currency_banked != 'undefined'
          && parseInt(update_fields.currency_banked) < 0
          && typeof update_fields.pass != 'undefined'
          && update_fields.pass.length > 0
         ) {
        if (parseInt(update_fields.currency_banked) <= this.#_currency_banked) {
          let results = await global.query("UPDATE player SET currency_banked=currency_banked + ? WHERE uuid_sl=?", [Math.abs(update_fields.currency_banked), update_fields.pass]);
          if (results.affectedRows <= 0) {
            throw new Error('Payment cancelled. Recipient not in database.');
          }

          let other_player = await global.query("SELECT player_id FROM player WHERE uuid_sl=?", [update_fields.pass]);
          if (other_player.length > 0) {
            await global.query("INSERT INTO player_log SET player_id=?, instant=NOW(), source_name='Stat Change', currency_banked=?", [other_player[0].player_id, Math.abs(update_fields.currency_banked)]);
          }
        }
      }
      for (let x=0;x<Player.INTEGER_CHARACTERISTICS.length;x++) {
        if (typeof update_fields[Player.INTEGER_CHARACTERISTICS[x]] != 'undefined') {
          this[Player.INTEGER_CHARACTERISTICS[x]] = parseInt(update_fields[Player.INTEGER_CHARACTERISTICS[x]]);
          updates[Player.INTEGER_CHARACTERISTICS[x]] = parseInt(update_fields[Player.INTEGER_CHARACTERISTICS[x]]);
        }
      }
      await global.query("UPDATE player SET name_character=?,title=?,currency_banked=?,currency_bonus=?,experience=?,health=?,attack=?,defense=?,boost_attack=?,boost_defense=?,instant_last_defense=?,instant_created=?,instant_last_stat_auto_update=?,hover_color=?,lvl=?,day_last_worked=?,total_days_worked=? WHERE player_id=?",
                         [this.#_name_character,
                          this.#_title,
                          this.#_currency_banked,
                          this.#_currency_bonus,
                          this.#_experience,
                          this.#_health,
                          this.#_attack,
                          this.#_defense,
                          this.#_boost_attack,
                          this.#_boost_defense,
                          this.#_instant_last_defense,
                          this.#_instant_created,
                          this.#_instant_last_stat_auto_update,
                          this.#_hover_color,
                          this.#_lvl,
                          this.#_day_last_worked,
                          this.#_total_days_worked,
                          this.#_player_id
                       ]
      );

      updates.source = (typeof updates.source != 'undefined'?updates.source:'Stat Change');
      updates.currency_banked = (typeof updates.currency_banked != 'undefined'?updates.currency_banked:0);
      updates.experience = (typeof updates.experience != 'undefined'?updates.experience:0);
      updates.health = (typeof updates.health != 'undefined'?updates.health:0);
      updates.attack = (typeof updates.attack != 'undefined'?updates.attack:0);
      updates.defense = (typeof updates.defense != 'undefined'?updates.defense:0);
      updates.boost_attack = (typeof updates.boost_attack != 'undefined'?updates.boost_attack:0);
      updates.boost_defense = (typeof updates.boost_defense != 'undefined'?updates.boost_defense:0);

      await global.query("INSERT INTO player_log (player_id, instant, source_name, currency_banked, experience, health, attack, defense, boost_attack, boost_defense) VALUES (?,NOW(),?,?,?,?,?,?,?,?)",
                         [this.#_player_id,
                          updates.source,
                          updates.currency_banked,
                          updates.experience,
                          updates.health,
                          updates.attack,
                          updates.defense,
                          updates.boost_attack,
                          updates.boost_defense
                        ]
                        );
    } catch (error) {
      throw new Error(`Database error: ${error.message}`);
    }
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
    try {
      this.uuid_sl = global.http.body.uuid;
      global.db.query("SELECT * FROM player WHERE uuid_sl=?", [this.uuid_sl], 
        function (error, results, fields) {
          if (error) {
            throw new Error(error);
          } else if (results.length == 0) {
            throw new Error(`Player with UUID Key of ${this.uuid_sl} not found.`);
          } else {
            for (let i=0;i<results.length;i++) {
              for (let k in results[i]) {
                this[k] = results[i][k];
              }
            }
          }
        }
      );
    } catch (error) {
      throw new Exception(`Database error: ${error.message}`);
    }
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