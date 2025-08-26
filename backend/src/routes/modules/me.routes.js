import { Router } from 'express';
import { requireAuth, requireSociety } from '../../middlewares/auth.js';
import { getProfile, getPermissions } from '../../controllers/me.controller.js';

const router = Router();

router.use(requireAuth, requireSociety);
router.get('/profile', getProfile);
router.get('/permissions', getPermissions);

export default router;