<?php
namespace SLRPHUD;

class API {
  public static $DB;
  public static $HASH_SEED;
  PUBLIC STATIC $DB_DRIVER;

  public static function Init($hash_seed, $host, $username, $password, $database) {
    self::$HASH_SEED = $hash_seed;
    self::$DB = new \mysqli($host, $username, $password, $database);

    if (self::$DB->connect_errno) {
      throw new \Exception("Cannot connect to database. Error: " . self::$DB->connect_error);
    }
    self::$DB->set_charset("utf8mb4");

    self::$DB_DRIVER = new \mysqli_driver();
    self::$DB_DRIVER->report_mode = MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT;

    if (   isset($_POST['action'])
        && isset($_POST['uuid'])
        && isset($_POST['hash'])
        && strlen($_POST['uuid']) == 36
        && sha1($_POST['uuid'] . self::$HASH_SEED) == $_POST['hash']
       ) {
      include 'Player.php';

      $player = new Player();

      if ($_POST['action'] == 'r') {
        $player->Read();
      } else if ($_POST['action'] == 'u') {
        $player->Update();
      } else if ($_POST['action'] == 'a') {
        $response = $player->Attack();
        if ($response !== false) {
          echo $response; exit();
        }
      } else if ($_POST['action'] == 'w') {
        $player->Work();
      } else if ($_POST['action'] == 'c') {
        $response = $player->Create();
        if ($response !== false) {
          echo $response; exit();
        }
      }
      echo (string)$player;
    } else {
      throw new \Exception('Invalid request');
    }
  }
}
?>