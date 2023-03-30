<?php
namespace SLRPHUD;
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

include 'classes/API.php';

$hash_seed = '';
$db_host = '';
$db_username = '';
$db_password = '';
$db_database = '';

try {
  API::Init($hash_seed, $db_host, $db_username, $db_password, $db_database);
} catch (\Exception $e) {
  echo 'ERR,' . $e->getMessage();
}
?>