import { Sequelize } from 'sequelize';
import { loadEnv } from './env.js';

const env = loadEnv();

export const sequelize = new Sequelize(env.DB_NAME, env.DB_USER, env.DB_PASS, {
	host: env.DB_HOST,
	port: env.DB_PORT,
	dialect: 'postgres',
	logging: env.NODE_ENV === 'development' ? console.log : false,
	dialectOptions: env.DB_SSL ? { ssl: { require: true, rejectUnauthorized: false } } : {},
	define: {
		freezeTableName: true,
		underscored: true,
		timestamps: false,
	},
});

export async function assertDbConnection() {
	try {
		await sequelize.authenticate();
		console.log('Database connected');
	} catch (err) {
		console.error('Database connection failed', err);
		throw err;
	}
}