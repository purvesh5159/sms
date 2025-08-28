import { sequelize } from '../config/sequelize.js';

export async function getProfile(req, res, next) {
	try {
		const userId = req.user.userId;
		const societyId = req.societyId;
		const [[user]] = await sequelize.query(
			`SELECT id, full_name, email, phone, role, is_active, created_at, updated_at
			 FROM users WHERE id = :uid LIMIT 1`,
			{ replacements: { uid: userId }, type: sequelize.QueryTypes.SELECT }
		);
		if (!user) return res.status(404).json({ error: 'User not found' });
		let roles = [];
		if (societyId) {
			roles = await sequelize.query(
				`SELECT r.name
				 FROM society_memberships sm
				 JOIN society_user_roles sur ON sur.membership_id = sm.id AND sur.society_id = sm.society_id
				 JOIN roles r ON r.id = sur.role_id AND r.society_id = sm.society_id
				 WHERE sm.user_id = :uid AND sm.society_id = :sid`,
				{ replacements: { uid: userId, sid: societyId }, type: sequelize.QueryTypes.SELECT }
			);
		}
		res.json({ user, societyId, roles: roles.map(r => r.name) });
	} catch (e) { next(e); }
}

export async function getPermissions(req, res, next) {
	try {
		const userId = req.user.userId;
		const societyId = req.societyId;
		const rows = await sequelize.query(
			`SELECT p.module, p.action
			 FROM society_memberships sm
			 JOIN society_user_roles sur ON sur.membership_id = sm.id AND sur.society_id = sm.society_id
			 JOIN role_permissions rp ON rp.role_id = sur.role_id
			 JOIN permissions p ON p.id = rp.permission_id
			 WHERE sm.user_id = :uid AND sm.society_id = :sid
			 ORDER BY p.module, p.action`,
			{ replacements: { uid: userId, sid: societyId }, type: sequelize.QueryTypes.SELECT }
		);
		res.json({ permissions: rows });
	} catch (e) { next(e); }
}