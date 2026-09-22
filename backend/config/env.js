require('dotenv').config();

const requiredEnvironmentVariables = [
  'DB_HOST',
  'DB_USER',
  'DB_PASSWORD',
  'DB_NAME',
  'JWT_SECRET',
];

for (const variableName of requiredEnvironmentVariables) {
  if (!process.env[variableName]) {
    throw new Error(`Missing required environment variable: ${variableName}`);
  }
}

module.exports = {
  database: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  },

  server: {
    port: Number(process.env.SERVER_PORT || 5000),
    environment: process.env.NODE_ENV || 'development',
  },

  jwt: {
    secret: process.env.JWT_SECRET,
  },
};