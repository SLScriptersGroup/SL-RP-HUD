const crypto = require('crypto');
const shasum = crypto.createHash('sha1');
const Player = require('player.js');
class API {
  static HASH_SEED;
  
  constructor() {}

  static Init(http_request) {
    if (typeof http_request.body.action != 'undefined'
        && typeof http_request.body.uuid != 'undefined'
        && typeof http_request.body.hash != 'undefined'
        && http_request.body.uuid.length == 36
        && shasum.update(http_request.body.uuid + API.HASH_SEED).digest('hex') == http_request.body.hash) {
      const player = new Player();
      switch (http_request.body.action) {
        case 'r':
          $player->Read();
          break;
        case 'u':
          $player->Update();
          break;
        case 'a':
          let attack_response = $player->Attack();
          if (attack_response !== false) {
            return attack_response;
            exit();
          }
          break;
        case 'w':
          $player->Work();
          break;
        case 'c':
          let create_response = $player->Create();
          if (create_response !== false) {
            return create_response;
            exit();
          }
          break;
      }
      return player.toString();
    } else {
      throw new Error('Invalid request');
    }
  }
}
module.exports = API;