import { Router } from 'express';
import { body, param } from 'express-validator';
import { requireAuth, requireSociety, requirePermission } from '../../middlewares/auth.js';
import { sequelize } from '../../config/sequelize.js';

const router = Router();

router.use(requireAuth, requireSociety);

router.get('/', requirePermission('complaints', 'read'), async (req, res, next) => {
	try {
		const rows = await sequelize.query(
			`SELECT c.id, c.category, c.description, c.status, c.priority,
			        c.created_at, c.updated_at,
			        f.number AS flat_number, t.name AS tower_name
			 FROM complaints c
			 JOIN flats f ON f.id = c.flat_id AND f.society_id = c.society_id
			 JOIN towers t ON t.id = f.tower_id AND t.society_id = f.society_id
			 WHERE c.society_id = :sid
			 ORDER BY c.created_at DESC`,
			{ replacements: { sid: req.societyId }, type: sequelize.QueryTypes.SELECT }
		);
		res.json(rows);
	} catch (e) { next(e); }
});

router.post('/', [
	requirePermission('complaints', 'create'),
	body('flatId').isInt({ min: 1 }),
	body('category').isString().isLength({ min: 1 }),
	body('description').isString().isLength({ min: 1 }),
	body('priority').optional().isInt({ min: 1, max: 5 })
], async (req, res, next) => {
	try {
		const { flatId, category, description, priority } = req.body;
		const [[row]] = await sequelize.query(
			`INSERT INTO complaints (society_id, flat_id, created_by_user_id, category, description, priority)
			 VALUES (:sid, :flatId, :uid, :category, :description, COALESCE(:priority, 3))
			 RETURNING id, category, description, status, priority` ,
			{ replacements: { sid: req.societyId, flatId, uid: req.user.userId, category, description, priority }, type: sequelize.QueryTypes.INSERT }
		);
		res.status(201).json(row);
	} catch (e) { next(e); }
});

router.patch('/:id/status', [
	requirePermission('complaints', 'update'),
	param('id').isInt({ min: 1 }),
	body('status').isIn(['open','in_progress','closed'])
], async (req, res, next) => {
	try {
		const id = Number(req.params.id);
		const { status } = req.body;
		const [[row]] = await sequelize.query(
			`UPDATE complaints SET status = :status, updated_at = now()
			 WHERE id = :id AND society_id = :sid
			 RETURNING id, status, updated_at`,
			{ replacements: { id, status, sid: req.societyId }, type: sequelize.QueryTypes.UPDATE }
		);
		if (!row) return res.status(404).json({ error: 'Not found' });
		res.json(row);
	} catch (e) { next(e); }
});

export default router;