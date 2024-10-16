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
  DB_TEST_DIALECT,
  DB_PROD_DATABASE,
  DB_PROD_USERNAME,
  DB_PROD_PASSWORD,
  DB_PROD_HOST,
  DB_PROD_DIALECT
} = process.env;

/**
 * Configuration de la base de données pour différents environnements.
 * 
 * @module databaseConfig
 * @type {Object}
 * @property {Object} development - Configuration de la base de données pour l'environnement de développement.
 * @property {string} development.username - Nom d'utilisateur de la base de données pour le développement.
 * @property {string} development.password - Mot de passe de la base de données pour le développement.
 * @property {string} development.database - Nom de la base de données pour le développement.
 * @property {string} development.host - Hôte de la base de données pour le développement.
 * @property {string} development.dialect - Dialecte de la base de données pour le développement.
 * 
 * @property {Object} test - Configuration de la base de données pour l'environnement de test.
 * @property {string} test.username - Nom d'utilisateur de la base de données pour le test.
 * @property {string} test.password - Mot de passe de la base de données pour le test.
 * @property {string} test.database - Nom de la base de données pour le test.
 * @property {string} test.host - Hôte de la base de données pour le test.
 * @property {string} test.dialect - Dialecte de la base de données pour le test.
 * 
 * @property {Object} production - Configuration de la base de données pour l'environnement de production.
 * @property {string} production.username - Nom d'utilisateur de la base de données pour la production.
 * @property {string} production.password - Mot de passe de la base de données pour la production.
 * @property {string} production.database - Nom de la base de données pour la production.
 * @property {string} production.host - Hôte de la base de données pour la production.
 * @property {string} production.dialect - Dialecte de la base de données pour la production.
 */

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
    username: DB_PROD_USERNAME,
    password: DB_PROD_PASSWORD,
    database: DB_PROD_DATABASE,
    host: DB_PROD_HOST,
    dialect: DB_PROD_DIALECT
  }
};