import { Router } from 'express';
import { body } from 'express-validator';
import { login, devLogin } from '../../controllers/auth.controller.js';
import { loadEnv } from '../../config/env.js';

const env = loadEnv();
const router = Router();

router.post('/login', [
	body('email').isEmail(),
	body('password').isString().isLength({ min: 3 }),
	body('societyId').optional().isInt({ min: 1 })
], login);

if (env.ALLOW_DEV_LOGIN) {
	router.post('/dev-login', [
		body('email').isEmail(),
		body('societyId').optional().isInt({ min: 1 })
	], devLogin);
}

export default router;