import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import routes from './routes/index.js';
import { loadEnv } from './config/env.js';

const env = loadEnv();
const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));

const authLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 100,
	standardHeaders: true,
	legacyHeaders: false,
});
app.use('/api/auth', authLimiter);

app.get('/health', (req, res) => {
	res.json({ ok: true });
});

app.use('/api', routes);

// Not found
app.use((req, res) => {
	res.status(404).json({ error: 'Not found' });
});

// Error handler
app.use((err, req, res, next) => {
	console.error(err);
	const status = err.status || 500;
	res.status(status).json({ error: err.message || 'Internal Server Error' });
});

export default app;