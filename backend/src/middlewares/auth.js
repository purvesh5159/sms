import jwt from 'jsonwebtoken';
import { loadEnv } from '../config/env.js';
import { sequelize } from '../config/sequelize.js';

const env = loadEnv();

export function requireAuth(req, res, next) {
	const header = req.headers.authorization || '';
	const token = header.startsWith('Bearer ') ? header.slice(7) : null;
	if (!token) return res.status(401).json({ error: 'Unauthorized' });
	try {
		const payload = jwt.verify(token, env.JWT_SECRET);
		req.user = payload; // { userId, email, societyId }
		next();
	} catch (e) {
		return res.status(401).json({ error: 'Invalid token' });
	}
}

export function requireSociety(req, res, next) {
	const societyId = Number(req.headers['x-society-id'] || req.user?.societyId);
	if (!societyId) return res.status(400).json({ error: 'society_id required' });
	req.societyId = societyId;
	next();
}

export function requirePermission(moduleName, action) {
	return async function(req, res, next) {
		const userId = req.user?.userId;
		const societyId = req.societyId;
		if (!userId || !societyId) return res.status(401).json({ error: 'Unauthorized' });
		try {
			const [rows] = await sequelize.query(
				`SELECT 1
				 FROM society_memberships sm
				 JOIN society_user_roles sur ON sur.membership_id = sm.id AND sur.society_id = sm.society_id
				 JOIN role_permissions rp ON rp.role_id = sur.role_id
				 JOIN permissions p ON p.id = rp.permission_id
				 WHERE sm.user_id = :userId AND sm.society_id = :societyId
				   AND p.module = :module AND p.action = :action
				 LIMIT 1` ,
				{ replacements: { userId, societyId, module: moduleName, action }, type: sequelize.QueryTypes.SELECT }
			);
			if (!rows || rows.length === 0) return res.status(403).json({ error: 'Forbidden' });
			return next();
		} catch (e) {
			return next(e);
		}
	};
}