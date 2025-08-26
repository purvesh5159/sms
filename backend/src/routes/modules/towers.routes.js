import { Router } from 'express';
import { body, param } from 'express-validator';
import { requireAuth, requireSociety, requirePermission } from '../../middlewares/auth.js';
import { sequelize } from '../../config/sequelize.js';

const router = Router();

router.use(requireAuth, requireSociety);

router.get('/', requirePermission('towers', 'read'), async (req, res, next) => {
	try {
		const rows = await sequelize.query('SELECT id, name, address, num_floors FROM towers WHERE society_id = :sid ORDER BY name', {
			replacements: { sid: req.societyId },
			type: sequelize.QueryTypes.SELECT,
		});
		res.json(rows);
	} catch (e) { next(e); }
});

router.post('/', [
	requirePermission('towers', 'create'),
	body('name').isString().isLength({ min: 1 }),
	body('address').optional().isString(),
	body('num_floors').optional().isInt({ min: 1 })
], async (req, res, next) => {
	try {
		const { name, address, num_floors } = req.body;
		const [[row]] = await sequelize.query(
			'INSERT INTO towers (society_id, name, address, num_floors) VALUES (:sid, :name, :address, :num_floors) ON CONFLICT DO NOTHING RETURNING id, name, address, num_floors',
			{ replacements: { sid: req.societyId, name, address, num_floors }, type: sequelize.QueryTypes.INSERT }
		);
		res.status(201).json(row);
	} catch (e) { next(e); }
});

export default router;