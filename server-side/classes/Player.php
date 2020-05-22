<?php
namespace SLRPHUD;

class Player {
  const MAX_HEALTH = 10;
  const MAX_ATTACK = 5;
  const MAX_DEFENSE = 5;
  const DROPS_PER_24_HOURS = 8;
  const FIGHT_WINNER_EXPERIENCE = 2;
  const FIGHT_LOSER_EXPERIENCE = 1;
  const FIGHT_LOSER_HEALTH = -1;
  const CHECK_IN_NUM_DAYS_FOR_BONUS = 5;
  const CHECK_IN_XP_BONUS = 1;

  const INTEGER_CHARACTERISTICS = array('currency_banked'=>'currency_banked',
                                        'experience'=>'experience',
                                        'attack'=>'attack',
                                        'defense'=>'defense',
                                        'boost_attack'=>'boost_attack',
                                        'boost_defense'=>'boost_defense'
                                       );

  private $_player_id = 0;
  private $_username_sl = '';
  private $_uuid_sl = '';
  private $_name_character = '';
  private $_title = '';
  private $_currency_banked = 0;
  private $_currency_bonus = 0;
  private $_experience = 0;
  private $_health = 0;
  private $_attack = 0;
  private $_defense = 0;
  private $_boost_attack = 0;
  private $_boost_defense = 0;
  private $_instant_last_defense = '';
  private $_instant_created = '';
  private $_instant_last_stat_auto_update = '';
  private $_hover_color = '';
  private $_lvl = 0;
  private $_day_last_worked = '';
  private $_total_days_worked = 0;

  private $_player_paid;

  public function Update($update_fields = false) {
    $this->Read();
    if ($update_fields == false) {
      $update_fields = $_POST;
    }
    try {
      $updates = array();
      if (isset($update_fields['name'])) {
        $this->_setter('name_character', $update_fields['name']);
      }
      if (isset($update_fields['title'])) {
        $this->_setter('title', $update_fields['title']);
      }
      if (isset($update_fields['hover_color']) && strlen($update_fields['hover_color']) > 0) {
        $this->_setter('hover_color', $update_fields['hover_color']);
      }
      if (isset($update_fields['health']) && strlen($update_fields['health']) > 0) {
        $updates['health'] = $update_fields['health'];
        $this->_setter('health', $this->_health + $update_fields['health']);
      }
      if (   isset($update_fields['currency_banked'])
          && (int)$update_fields['currency_banked'] < 0
          && isset($update_fields['pass'])
          && strlen($update_fields['pass']) > 0
         ) {
        //Transferring funds
        if ((int)$update_fields['currency_banked'] <= $this->_currency_banked) {
          $stmt = API::$DB->prepare("UPDATE player
                                        SET currency_banked = currency_banked + ?
                                      WHERE uuid_sl=?");
          $stmt->bind_param("is", abs($update_fields['currency_banked']), $update_fields['pass']);
          $stmt->execute();
          if ($stmt->affected_rows <= 0) {
            throw new \Exception('Payment cancelled. Recipient not in database.');
          }
          $stmt->close();

          $stmt = API::$DB->prepare("SELECT player_id FROM player WHERE uuid_sl=?");
          $stmt->bind_param("s", $update_fields['pass']);
          $stmt->execute();
          $result = $stmt->get_result();
          if ($result->num_rows > 0) {
            $other_player = $result->fetch_object();

            $stmt->close();

            $stmt = API::$DB->prepare("INSERT INTO player_log
                                               SET player_id=?,
                                                   instant=NOW(),
                                                   source_name='Stat Change',
                                                   currency_banked=?");
              $stmt->bind_param("ii", $other_player->player_id, abs($update_fields['currency_banked']));
              $stmt->execute();
              $stmt->close();
          }
        } else {
          throw new \Exception('Payment cancelled. You cannot pay more than you have.');
        }
      }
      foreach (self::INTEGER_CHARACTERISTICS as $field) {
        if (isset($update_fields[$field])) {
          $this->_setter($field, $this->{'_' . $field} + (int)$update_fields[$field]);
          $updates[$field] = (INT)$update_fields[$field];
        }
      }
      $sql = "UPDATE player SET name_character=?,title=?,currency_banked=?,currency_bonus=?,experience=?,health=?,attack=?,defense=?,boost_attack=?,boost_defense=?,instant_last_defense=?,instant_created=?,instant_last_stat_auto_update=?,hover_color=?,lvl=?,day_last_worked=?,total_days_worked=? WHERE player_id=?";
      $stmt = API::$DB->prepare($sql);
      $stmt->bind_param("ssiiiiiiiissssisii", $this->_name_character,
                                              $this->_title,
                                              $this->_currency_banked,
                                              $this->_currency_bonus,
                                              $this->_experience,
                                              $this->_health,
                                              $this->_attack,
                                              $this->_defense,
                                              $this->_boost_attack,
                                              $this->_boost_defense,
                                              $this->_instant_last_defense,
                                              $this->_instant_created,
                                              $this->_instant_last_stat_auto_update,
                                              $this->_hover_color,
                                              $this->_lvl,
                                              $this->_day_last_worked,
                                              $this->_total_days_worked,
                                              $this->_player_id
                                              );
      $stmt->execute();
      $stmt->close();

      $sql = "INSERT INTO player_log (player_id, instant, source_name, currency_banked, experience, health, attack, defense, boost_attack, boost_defense) VALUES (?,NOW(),?,?,?,?,?,?,?,?)";
      $stmt = API::$DB->prepare($sql);

      $updates['source'] = (isset($updates['source'])?$updates['source']:'Stat Change');
      $updates['currency_banked'] = (isset($updates['currency_banked'])?$updates['currency_banked']:0);
      $updates['experience'] = (isset($updates['experience'])?$updates['experience']:0);
      $updates['health'] = (isset($updates['health'])?$updates['health']:0);
      $updates['attack'] = (isset($updates['attack'])?$updates['attack']:0);
      $updates['defense'] = (isset($updates['defense'])?$updates['defense']:0);
      $updates['boost_attack'] = (isset($updates['boost_attack'])?$updates['boost_attack']:0);
      $updates['boost_defense'] = (isset($updates['boost_defense'])?$updates['boost_defense']:0);
      $stmt->bind_param("isiiiiiii", $this->_player_id,
                                     $update_fields['source'],
                                     $updates['currency_banked'],
                                     $updates['experience'],
                                     $updates['health'],
                                     $updates['attack'],
                                     $updates['defense'],
                                     $updates['boost_attack'],
                                     $updates['boost_defense']
                       );
      $stmt->execute();
      $stmt->close();
    } catch (\mysqli_sql_exception $e) {
      throw new \Exception("Database error: " . $e->__toString());
    }
  }
  public function Work() {
    $this->Read();
    try {
      $level_info = $this->_experienceToLevel($this->_experience);
      if ($this->_day_last_worked < date('Y-m-d') || strlen($this->_day_last_worked) == 0) {
        $this->_setter('player_paid', round($level_info['pay'] * (1 + $this->_currency_bonus), 0));
        $sql = "";
        if (($this->_total_days_worked + 1)%self::CHECK_IN_NUM_DAYS_FOR_BONUS == 0) {
          $stmt = API::$DB->prepare("UPDATE player
                                        SET currency_banked = currency_banked + ?,
                                            day_last_worked=CURDATE(),
                                            total_days_worked = total_days_worked + 1,
                                            experience=experience + ?
                                      WHERE player_id=?");
          $bonus = self::CHECK_IN_XP_BONUS;
          $stmt->bind_param("iii", $this->_player_paid, $bonus, $this->_player_id);
          $stmt->execute();
          $stmt->close();

          $this->_setter('currency_banked', $this->_currency_banked + $this->_player_paid);
          $this->_setter('experience', $this->_experience +  self::CHECK_IN_XP_BONUS);
          $level_info = $this->_experienceToLevel($this->_experience);
          $this->_setter('lvl', $level_info['level']);

          $stmt = API::$DB->prepare("INSERT INTO player_log
                                             SET player_id=?,
                                                 instant=NOW(),
                                                 source_name='Daily Check-In',
                                                 currency_banked=?,
                                                 experience=" . self::CHECK_IN_XP_BONUS);
          $stmt->bind_param("ii", $this->_player_id, $this->_player_paid);
        } else {
          $stmt = API::$DB->prepare("UPDATE player
                                        SET currency_banked = currency_banked + ?,
                                            day_last_worked=CURDATE(),
                                            total_days_worked = total_days_worked + 1
                                      WHERE player_id=?");
          $stmt->bind_param("ii", $this->_player_paid, $this->_player_id);
          $stmt->execute();
          $stmt->close();

          $stmt = API::$DB->prepare("INSERT INTO player_log
                                             SET player_id=?,
                                                 instant=NOW(),
                                                 source_name='Daily Check-In',
                                                 currency_banked=?"
                                   );
          $stmt->bind_param("ii", $this->_player_id, $this->_player_paid);
        }
        
        $stmt->execute();
        $stmt->close();
      } else {
        throw new \Exception('You have already received your daily stipend.');
      }
    } catch (\mysqli_sql_exception $e) {
      throw new \Exception("Database error: " . $e->__toString());
    }
  }
  public function Attack() {
    $this->Read();
    try {
      $attacker = $defender = false;

      $stmt = API::$DB->prepare("SELECT * FROM player WHERE uuid_sl IN (?, ?)");
      $stmt->bind_param("ss", $_POST['defender'], $_POST['uuid']);
      $stmt->execute();
      $result = $stmt->get_result();
      if ($result->num_rows == 2) {
        while ($fighter = $result->fetch_object()) {
          if ($fighter->uuid_sl == $_POST['uuid']) {
            $attacker = $fighter;
          } else if ($fighter->uuid_sl == $_POST['defender']) {
            $defender = $fighter;
          }
        }
        $stmt->close();
        if (   $_POST['stats'] != "Pick Winner"
            && ($attacker->health == 0 || $defender->health == 0)
           ) {
          throw new \Exception('Everyone must have at least one unit of health if losing to fight.');
        } else if ($attacker !== false && $defender !== false) {
          list ($winner, $loser) = $this->_placeBattle($attacker, $defender);
          if ($_POST['stats'] != "Pick Winner") {
            $stmt = API::$DB->prepare("UPDATE player SET experience = experience + ?, health = health + ? WHERE uuid_sl=?");
            $win_xp = self::FIGHT_WINNER_EXPERIENCE;
            $zero = 0;
            $stmt->bind_param("iis", $win_xp, $zero, $winner);
            $stmt->execute();

            $lose_xp = self::FIGHT_LOSER_EXPERIENCE;
            $lose_health = self::FIGHT_LOSER_HEALTH;
            $stmt->bind_param("iis", $lose_xp, $lose_health, $loser);
            $stmt->execute();
            
            $stmt->close();

            $stmt = API::$DB->prepare("INSERT INTO player_log SET player_id=?, instant=NOW(), source_name='Attack Win', experience=" . self::FIGHT_WINNER_EXPERIENCE);
            $player_id = $attacker->uuid_sl == $winner?$attacker->player_id:$defender->player_id;
            $stmt->bind_param("i", $player_id);
            $stmt->execute();
            $stmt->close();

            $stmt = API::$DB->prepare("INSERT INTO player_log SET player_id=?, instant=NOW(), source_name='Attack Lose', experience=" . self::FIGHT_LOSER_EXPERIENCE . ",health=" . self::FIGHT_LOSER_HEALTH);
            $player_id = $attacker->uuid_sl == $winner?$defender->player_id:$attacker->player_id;
            $stmt->bind_param("i", $player_id);
            $stmt->execute();
            $stmt->close();
          }
          return 'ATTACK,secondlife:///app/agent/' . $winner . '/about won!,' . $defender->uuid_sl;
        } else {
          throw new \Exception('Not all players were found.');
        }
      } else {
        throw new \Exception('Not all players were found.');
      }
    } catch (\mysqli_sql_exception $e) {
      throw new \Exception("Database error: " . $e->__toString());
    }
    return false;
  }
  public function Create() {
    if (isset($_POST['quest'])) {
      $stmt = API::$DB->prepare("SELECT * FROM player WHERE uuid_sl=?");
      $stmt->bind_param("s", $_POST['uuid']);
      $stmt->execute();
      $result = $stmt->get_result();
      if ($result->num_rows == 1) {
        $player = $result->fetch_object();
        $stmt->close();

        $stmt = API::$DB->prepare("SELECT player_action_id FROM player_action WHERE player_id=? AND quest_action=?");
        $stmt->bind_param("is", $player->player_id, $_POST['quest']);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows == 0) {
          $stmt->close();

          $stmt = API::$DB->prepare("INSERT INTO player_action
                                             SET player_id=?,
                                                 instant_completed=NOW(),
                                                 quest_action=?");
          $stmt->bind_param("is", $player->player_id, $_POST['quest']);
          $stmt->execute();
          $stmt->close();

          if (isset($_POST['reward']) && is_array($_POST['reward'])) {
            $this->Update($_POST['reward']);
            return $_POST['quest'] . ',COMPLETED';;
          }
        } else {
          return $_POST['quest'] . ',PREVIOUS';
        }
      } else {
        throw new \Exception('Player with UUID Key of ' . preg_replace('/[^a-z0-9\-]/i', '', $_POST['uuid']) . ' not found.');
      }
    } else if (isset($_POST['item'])) {
      $stmt = API::$DB->prepare("SELECT * FROM player WHERE uuid_sl=?");
      $stmt->bind_param("s", $_POST['uuid']);
      $stmt->execute();
      $result = $stmt->get_result();
      if ($result->num_rows == 1) {
        $player = $result->fetch_object();
        $stmt->close();

        $stmt = API::$DB->prepare("INSERT INTO player_to_item
                                           SET player_id=?,
                                               instant_created=NOW(),
                                               source=?,
                                               is_crit_fail=?,
                                               instant_cooldown_expires=?,
                                               item=?"
                 );

        $is_crit = ($_POST['is_crit_fail'] == 'Yes'?'Yes':'No');
        $cooldown = (isset($_POST['cooldown'])?"'" . date('Y-m-d H:i:s', strtotime(((int)$_POST['cooldown'] >= 0?'+':'') . (int)$_POST['cooldown'] . ' seconds')) . "'":'NULL');
        $stmt->bind_param("issss", $player->player_id,
                                   $_POST['source'],
                                   $is_crit,
                                   $cooldown,
                                   $_POST['item']
                         );
        $stmt->execute();
        $stmt->close();
        return 'SILENT';
      } else {
        throw new \Exception('Player with UUID Key of ' . preg_replace('/[^a-z0-9\-]/i', '', $_POST['uuid']) . ' not found.');
      }
    } else if (   isset($_POST['user']) && strlen($_POST['user']) > 0
               && isset($_POST['name']) && strlen($_POST['name']) > 0
               && isset($_POST['title'])
              ) { //New user
      
      $stmt = API::$DB->prepare("INSERT INTO player SET username_sl=?, uuid_sl=?, name_character=?, title=?, hover_color=?");
      $hover_color = '1,1,1';

      if (isset($_POST['hover_color']) && strlen($_POST['hover_color']) > 0) {
        $hover_color = preg_replace('/[^A-F0-9]/', '', strtoupper($_POST['hover_color']));
        if (strlen($hover_color) == 6) {
          $hover_color = substr(hexdec(substr($hover_color, 0, 2))/255, 0, 8) . ',' . substr(hexdec(substr($hover_color, 2, 2))/255, 0, 8) . ',' . substr(hexdec(substr($hover_color, 4, 2))/255, 0, 8);
        } else {
          $hover_color = preg_replace('/[^0-9,\.]/', '', $_POST['hover_color']);
          if (substr_count($hover_color, ',') == 2) {
            $hover_color = $hover_color;
          } else {
            $hover_color = '1,1,1';
          }
        }
        $hover_color = preg_replace('/[<> ]/', '', $hover_color);
      }

      $stmt->bind_param("sssss", $_POST['user'],
                                 $_POST['uuid'],
                                 $_POST['name'],
                                 str_replace(',', '', $_POST['title']),
                                 $hover_color
                       );
      $stmt->execute();
      $stmt->close();

      $stmt = API::$DB->prepare("INSERT INTO player_log SET player_id=?, instant=NOW(), source_name='User Created'");
      $stmt->bind_param("i", API::$DB->insert_id);
      $stmt->execute();
      $stmt->close();

      $this->Read();
    } else {
      throw new \Exception('Cannot create player with missing fields.');
    }
    return false;
  }
  public function Read() {
    try {
      $this->_setter('uuid_sl', $_POST['uuid']);

      $stmt = API::$DB->prepare("SELECT * FROM player WHERE uuid_sl=?");
      $stmt->bind_param("s", $_POST['uuid']);
      $stmt->execute();
      $result = $stmt->get_result();
      if ($result->num_rows > 0) {
        $player = $result->fetch_object();
        foreach ($player as $field=>$value) {
          $this->{'_' . $field} = $value;
        }
      } else {
        throw new \Exception('Player with UUID Key of ' . $this->_uuid_sl . ' not found.');
      }
      $stmt->close();

      if (isset($_POST['is_drop']) && $_POST['is_drop'] == 1) {
        $num_drops = 0;
        $stmt = API::$DB->prepare("SELECT COUNT(*) AS qty
                                     FROM player_to_item
                                    WHERE player_id=?
                                      AND instant_created > '" . date('Y-m-d H:i:s', strtotime('-24 hours')) . "'");
        $stmt->bind_param("i", $this->_player_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
          $player_to_item_count = $result->fetch_object();
          if ($player_to_item_count->qty >= self::DROPS_PER_24_HOURS) {
            throw new \Exception('(( 24 hour drop limit reached. Please try again later. ))');
          }
        }
        $stmt->close();

        $stmt = API::$DB->prepare("SELECT instant_cooldown_expires
                                     FROM player_to_item
                                    WHERE player_id=?
                                      AND source=?");
        $stmt->bind_param("is", $this->_player_id, $_POST['source']);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows > 0) {
          $player_to_item_count = $result->fetch_object();
    
          if (   strlen($player_to_item_count->instant_cooldown_expires) > 0
              && $player_to_item_count->instant_cooldown_expires > date('Y-m-d H:i:s')
             ) {
            throw new \Exception('(( The item fails to respond due to cooldown constraints. Try again later. ))');
          }
        }
        $stmt->close();
      }
    } catch (\mysqli_sql_exception $e) {
      throw new \Exception("Database error: " . $e->__toString());
    }
  }
  public function __set($name, $val) {
    $this->_setter($name, $val);
  }
  public function __toString() {
    $level_info = $this->_experienceToLevel($this->_experience);
    $response = 'STAT,'
              . $this->_name_character . ','
              . $this->_title . ','
              . $this->_currency_banked . ','
              . $level_info['xp'] . ','
              . $this->_health . ','
              . $this->_attack . ','
              . $this->_defense . ','
              . $this->_boost_attack . ','
              . $this->_boost_defense . ','
              . (int)(   strlen($this->_instant_last_defense) == 0
                      || (strtotime($this->_instant_last_defense) + 60*60 > time())
                    ) . ',' //Not implemented client side
              . $this->_hover_color . ',';
    if (isset($_POST['pass'])) {
      $response .= $_POST['pass'];
    }
    $response .= ',' . $level_info['level']
               . ',' . $level_info['xp_needed'];
    if ((int)$this->_player_paid > 0) {
      $response .= ',' . (int)$this->_player_paid;
    }
    return $response;
  }
  function _placeBattle($attacker, $defender) {
    $offensive = ($attacker->health/10) * $attacker->attack;
    $defensive = ($defender->health/10) * $defender->defense;
    $max = ceil($offensive + $defensive);
    $dice_roll = mt_rand(0, $max);
    if ($dice_roll <= $offensive) {
      return array($attacker->uuid_sl, $defender->uuid_sl);
    } else {
      return array($defender->uuid_sl, $attacker->uuid_sl);
    }
  }
  private function _experienceToLevel($xp) {
    include 'player-levels.php';
    $result = array('level'=>1, 'xp'=>0, 'xp_needed'=>10, 'pay'=>60);
    
    $num_lvl = count($player_levels);
    for ($i=$num_lvl - 1;$i>-1;$i--) {
      if ($xp >= $player_levels[$i]['min_xp']) {
        $result['level'] = $player_levels[$i]['lvl'];
        $result['pay'] = $player_levels[$i]['pay'];
        $result['xp'] = $xp - $player_levels[$i]['min_xp'];
        if ($i < count($player_levels) - 1) {
          $result['xp_needed'] = $player_levels[$i + 1]['min_xp'];
        } else {
          $result['xp_needed'] = 0;
        }
        return $result;
      }
    }
    $result['xp'] = $xp;
    $result['xp_needed'] = $player_levels[0]['min_xp'];
    return $result;
  }
  private function _setter($name, $val) {
    if ($name == 'name') {
      $name = 'name_character';
    }
    if ($name == 'uuid_sl') {
      $val = preg_replace('/[^a-f0-9\-]/i', '', $val);
    } else if ($name == 'username_sl') {
      $val = preg_replace('/[^a-z0-9]/i', '', $val);
    } else if (   $name == 'player_id'
               || $name == 'currency_banked'
               || $name == 'currency_bonus'
               || $name == 'experience'
               || $name == 'total_days_worked'
             ) {
      $val = (int)$this->{'_' . $name} + (int)$val;
    } else if ($name == 'health') {
      $val = (int)$this->_health + (int)$val;
      if ($val > self::MAX_HEALTH) {
        $val = self::MAX_HEALTH;
      } else if ($val < 0) {
        $val = 0;
      }
    } else if (   $name == 'attack'
               || $name == 'boost_attack') {
      $val = (int)$this->{'_' . $name} + (int)$val;
      if ($val > self::MAX_ATTACK) {
        $val = self::MAX_ATTACK;
      } else if ($val < 0) {
        $val = 0;
      }
    } else if (   $name == 'defense'
               || $name == 'boost_defense') {
      $val = (int)$this->{'_' . $name} + (int)$val;
      if ($val > self::MAX_DEFENSE) {
        $val = self::MAX_DEFENSE;
      } else if ($val < 0) {
        $val = 0;
      }
    } else if (   $name == 'instant_last_defense'
               || $name == 'instant_created'
               || $name == 'instant_last_stat_auto_update'
             ) {
      if (($time = strtotime($val)) !== false) {
        $val = date('Y-m-d H:i:s', strtotime($val));
      } else {
        $val = '';
      }
    } else if ($name == 'day_last_worked') {
      if (($time = strtotime($val)) !== false) {
        $val = date('Y-m-d', strtotime($val));
      } else {
        $val = '';
      }
    } else if ($name == 'hover_color') {
      $val = preg_replace('/[^A-F0-9]/', '', strtoupper($val));
      if (strlen($val) == 6) {
        $val = substr(hexdec(substr($val, 0, 2))/255, 0, 8) . ',' . substr(hexdec(substr($val, 2, 2))/255, 0, 8) . ',' . substr(hexdec(substr($val, 4, 2))/255, 0, 8);
      } else {
        $val = preg_replace('/[^0-9,\.]/', '', $val);
        if (substr_count($val, ',') != 2) {
          $val = '1,1,1';
        }
      }
      $val = preg_replace('/[<> ]/', '', $val);
    } else if (   $name == 'name_character'
               || $name == 'title'
             ) {
      $val = str_replace(',', '', $val);
    }
    $this->{'_' . $name} = $val;
  }
}
?>
