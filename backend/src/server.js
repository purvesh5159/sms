import { createServer } from 'http';
import app from './app.js';
import { loadEnv } from './config/env.js';

const env = loadEnv();
const port = Number(env.PORT || 3001);

const server = createServer(app);
server.listen(port, () => {
	console.log(`API listening on http://localhost:${port}`);
});