const express = require('express');
const redis = require('redis');

const app = express();
const PORT = process.env.PORT || 3000;
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;

// Create Redis client
const redisClient = redis.createClient({
  socket: {
    host: REDIS_HOST,
    port: REDIS_PORT
  }
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('Connected to Redis'));

// Connect to Redis
(async () => {
  await redisClient.connect();
})();

app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', redis: redisClient.isOpen });
});

// Home page
app.get('/', async (req, res) => {
  const visits = await redisClient.incr('visits');
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Sample Workshop App</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 50px auto;
          padding: 20px;
          background: #f5f5f5;
        }
        .container {
          background: white;
          padding: 40px;
          border-radius: 10px;
          box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 { color: #333; }
        .counter {
          font-size: 3em;
          color: #667eea;
          margin: 20px 0;
        }
        .info {
          background: #f0f0f0;
          padding: 15px;
          border-radius: 5px;
          margin-top: 20px;
        }
        button {
          background: #667eea;
          color: white;
          border: none;
          padding: 10px 20px;
          border-radius: 5px;
          cursor: pointer;
          font-size: 1em;
          margin: 5px;
        }
        button:hover {
          background: #5568d3;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🎉 Sample Workshop Application</h1>
        <p>This page has been visited:</p>
        <div class="counter">${visits} times</div>
        
        <div>
          <button onclick="location.reload()">Refresh</button>
          <button onclick="fetch('/api/reset', {method: 'POST'}).then(() => location.reload())">Reset Counter</button>
        </div>
        
        <div class="info">
          <h3>Redis Connection Info</h3>
          <p><strong>Host:</strong> ${REDIS_HOST}</p>
          <p><strong>Port:</strong> ${REDIS_PORT}</p>
          <p><strong>Status:</strong> ${redisClient.isOpen ? '✅ Connected' : '❌ Disconnected'}</p>
        </div>
        
        <div class="info">
          <h3>API Endpoints</h3>
          <ul>
            <li><code>GET /</code> - This page</li>
            <li><code>GET /api/counter</code> - Get current counter value</li>
            <li><code>POST /api/reset</code> - Reset counter</li>
            <li><code>GET /health</code> - Health check</li>
          </ul>
        </div>
      </div>
    </body>
    </html>
  `);
});

// API: Get counter
app.get('/api/counter', async (req, res) => {
  const visits = await redisClient.get('visits') || 0;
  res.json({ visits: parseInt(visits) });
});

// API: Reset counter
app.post('/api/reset', async (req, res) => {
  await redisClient.set('visits', 0);
  res.json({ message: 'Counter reset', visits: 0 });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Redis host: ${REDIS_HOST}:${REDIS_PORT}`);
});

