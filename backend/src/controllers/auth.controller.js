import jwt from 'jsonwebtoken';
import { validationResult } from 'express-validator';
import { loadEnv } from '../config/env.js';
import { sequelize } from '../config/sequelize.js';
import { verifyPassword } from '../utils/password.js';

const env = loadEnv();

function signToken(payload) {
	return jwt.sign(payload, env.JWT_SECRET, { expiresIn: env.JWT_EXPIRES_IN });
}

export async function login(req, res, next) {
	try {
		const errors = validationResult(req);
		if (!errors.isEmpty()) return res.status(400).json({ errors: errors.array() });
		const { email, password, societyId } = req.body;
		const [[user]] = await sequelize.query('SELECT id, email, password_hash, is_active FROM users WHERE email = :email LIMIT 1', {
			replacements: { email },
			type: sequelize.QueryTypes.SELECT,
		});
		if (!user || !user.is_active) return res.status(401).json({ error: 'Invalid credentials' });
		const ok = await verifyPassword(password || '', user.password_hash);
		if (!ok) return res.status(401).json({ error: 'Invalid credentials' });

		let sid = societyId ? Number(societyId) : undefined;
		if (!sid) {
			const memberships = await sequelize.query('SELECT society_id FROM society_memberships WHERE user_id = :uid AND is_active = true', {
				replacements: { uid: user.id },
				type: sequelize.QueryTypes.SELECT,
			});
			sid = memberships?.[0]?.society_id;
		}
		const token = signToken({ userId: user.id, email: user.email, societyId: sid });
		return res.json({ token, user: { id: user.id, email: user.email, societyId: sid } });
	} catch (e) {
		return next(e);
	}
}

export async function devLogin(req, res, next) {
	try {
		if (!env.ALLOW_DEV_LOGIN) return res.status(403).json({ error: 'Disabled' });
		const { email, societyId } = req.body;
		const [[user]] = await sequelize.query('SELECT id, email FROM users WHERE email = :email LIMIT 1', {
			replacements: { email },
			type: sequelize.QueryTypes.SELECT,
		});
		if (!user) return res.status(404).json({ error: 'User not found' });
		const token = signToken({ userId: user.id, email: user.email, societyId: societyId ? Number(societyId) : undefined });
		return res.json({ token, user: { id: user.id, email: user.email, societyId } });
	} catch (e) {
		return next(e);
	}
}