import { Router } from 'express';
import authRouter from './modules/auth.routes.js';
import towersRouter from './modules/towers.routes.js';
import flatsRouter from './modules/flats.routes.js';
import complaintsRouter from './modules/complaints.routes.js';

const router = Router();

router.use('/auth', authRouter);
router.use('/towers', towersRouter);
router.use('/flats', flatsRouter);
router.use('/complaints', complaintsRouter);

export default router;