require('dotenv').config({path: '../.env'});

const {
  DB_USERNAME,
  DB_PASSWORD,
  DB_DATABASE,
  DB_HOST,
  DB_DIALECT,
  DB_TEST_USERNAME,
  DB_TEST_PASSWORD,
  DB_TEST_DATABASE,
  DB_TEST_HOST,
  DB_TEST_DIALECT
} = process.env;

module.exports = {
  development: {
    username: DB_USERNAME,
    password: DB_PASSWORD,
    database: DB_DATABASE,
    host: DB_HOST,
    dialect: DB_DIALECT
  },
  test: {
    username: DB_TEST_USERNAME,
    password: DB_TEST_PASSWORD,
    database: DB_TEST_DATABASE,
    host: DB_TEST_HOST,
    dialect: DB_TEST_DIALECT
  },
  production: {
    username: DB_USERNAME,
    password: DB_PASSWORD,
    database: DB_DATABASE,
    host: DB_HOST,
    dialect: DB_DIALECT
  }
};