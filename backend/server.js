const express = require('express');
const cors = require('cors');

const config = require('./config/env');
const { testDatabaseConnection } = require('./config/database');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (request, response) => {
  response.json({
    success: true,
    message: 'FadeLab API is running.',
  });
});

app.use((request, response) => {
  response.status(404).json({
    success: false,
    message: 'Route not found.',
  });
});

async function startServer() {
  try {
    await testDatabaseConnection();

    app.listen(config.server.port, () => {
      console.log(
        `Server running at http://localhost:${config.server.port}`
      );
    });
  } catch (error) {
    console.error('Unable to start server:', error.message);
    process.exit(1);
  }
}

startServer();