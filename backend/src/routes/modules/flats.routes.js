import { Router } from 'express';
import { body } from 'express-validator';
import { requireAuth, requireSociety, requirePermission } from '../../middlewares/auth.js';
import { sequelize } from '../../config/sequelize.js';

const router = Router();

router.use(requireAuth, requireSociety);

router.get('/', requirePermission('flats', 'read'), async (req, res, next) => {
	try {
		const rows = await sequelize.query(
			`SELECT f.id, f.number, f.floor, t.name AS tower_name
			 FROM flats f
			 JOIN towers t ON t.id = f.tower_id AND t.society_id = f.society_id
			 WHERE f.society_id = :sid
			 ORDER BY t.name, f.number`,
			{ replacements: { sid: req.societyId }, type: sequelize.QueryTypes.SELECT }
		);
		res.json(rows);
	} catch (e) { next(e); }
});

router.post('/', [
	requirePermission('flats', 'create'),
	body('towerId').isInt({ min: 1 }),
	body('number').isString().isLength({ min: 1 }),
	body('floor').optional().isInt()
], async (req, res, next) => {
	try {
		const { towerId, number, floor } = req.body;
		const [[row]] = await sequelize.query(
			`INSERT INTO flats (society_id, tower_id, number, floor)
			 VALUES (:sid, :towerId, :number, :floor)
			 ON CONFLICT DO NOTHING
			 RETURNING id, number, floor, tower_id`,
			{ replacements: { sid: req.societyId, towerId, number, floor }, type: sequelize.QueryTypes.INSERT }
		);
		res.status(201).json(row);
	} catch (e) { next(e); }
});

export default router;