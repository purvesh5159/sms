import dotenv from 'dotenv';

let cachedEnv = null;

export function loadEnv() {
	if (cachedEnv) return cachedEnv;
	dotenv.config();
	const env = {
		PORT: process.env.PORT || '3001',
		NODE_ENV: process.env.NODE_ENV || 'development',
		JWT_SECRET: process.env.JWT_SECRET || 'dev_super_secret_change_me',
		JWT_EXPIRES_IN: process.env.JWT_EXPIRES_IN || '7d',
		ALLOW_DEV_LOGIN: process.env.ALLOW_DEV_LOGIN === 'true',
		DB_HOST: process.env.DB_HOST || 'localhost',
		DB_PORT: Number(process.env.DB_PORT || '5432'),
		DB_NAME: process.env.DB_NAME || 'society_db',
		DB_USER: process.env.DB_USER || 'society_admin',
		DB_PASS: process.env.DB_PASS || 'society_pass',
		DB_SSL: process.env.DB_SSL === 'true',
	};
	cachedEnv = env;
	return env;
}