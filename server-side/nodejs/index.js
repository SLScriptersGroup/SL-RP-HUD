require('dotenv').config();

const API = require('./classes/api.js');

console.log(PlayerLevels);

const fs = require('node:fs');
const https = require('https');
const http = require('http');
const path = require('path');
const url = require('url');
const mysql = require('mysql');
const express = require('express');
const util = require('util');

global.db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_DATABASE,
  charset: 'utf8mb4',
});
global.query = util.promisify(db.query).bind(db);

const app = express();

app.post('/', function(req, res) {
  try {
    API.HASH_SEED = process.env.HASH_SEED;
    const response = API.Init(req);
    res.send(response);
  } catch (error) {
    res.send(error.message);
  }
  res.end();
});

app.listen(process.env.DB_HTTP_PORT);