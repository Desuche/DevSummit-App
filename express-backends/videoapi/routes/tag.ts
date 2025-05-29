import express from 'express';
import { getAllTags } from '../db';
import passport from 'passport';
const router = express.Router();

router.get(
	'/',
	// passport.authenticate('bearer', { session: false }),
	async (_req, res) => {
		try {
			const tags = await getAllTags();
			res.status(200).json(tags);
		} catch (error) {
			console.error('Error fetching tags:', error);
			res.status(500).json({ message: 'Internal server error' });
		}
	},
);

export default router;
