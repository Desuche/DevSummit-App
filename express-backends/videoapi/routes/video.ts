import express from 'express';
import multer from 'multer';
import fs from 'node:fs';
import { ObjectId } from 'mongodb';
import type { Video } from '../models';
import passport from 'passport';
import {
	createVideo,
	downvoteVideo,
	getAllVideos,
	getTagById,
	upvoteVideo,
} from '../db';
import path from 'node:path';

const TEMP_FILE_NAME_KEY = 'tempFilename';

const router = express.Router();

// const userId = '673d9ed9521c9185b228bea3';

const videoStoragePath = () => `${process.env.STORAGE_PATH!}videos/`;
const tempStoragePath = () => `${process.env.STORAGE_PATH!}temp/`;

(() => {
	if (!fs.existsSync(process.env.STORAGE_PATH!)) {
		throw new Error('Storage path does not exist');
	}

	if (!process.env.STORAGE_PATH!.endsWith('/')) {
		process.env.STORAGE_PATH! += '/';
	}

	if (!fs.existsSync(videoStoragePath())) {
		fs.mkdirSync(videoStoragePath());
	}

	if (!fs.existsSync(tempStoragePath())) {
		fs.mkdirSync(tempStoragePath());
	}
})();

const storage = multer.diskStorage({
	destination: (_req, _file, cb) => {
		cb(null, tempStoragePath());
	},
	filename: (req, file, cb) => {
		const uuid = crypto.randomUUID();
		const fileExtension = path.extname(file.originalname);
		const fileName = `${uuid}${fileExtension}`;
		req.body[TEMP_FILE_NAME_KEY] = fileName;
		cb(null, fileName);
	},
});
const upload = multer({ storage });

router.post(
	'/',
	passport.authenticate('bearer', { session: false }),
	upload.single('video'),
	async (req, res) => {
		const {
			tagId,
			title,
			description,
			[TEMP_FILE_NAME_KEY]: tempFilename,
		} = req.body;

		// currently every logged in user could upload a video (not from client side, but backend doesn't check)

		if (!req.file) {
			res.status(400).json({ message: 'No file uploaded' });
			return;
		}

		if (!tempFilename) {
			res.status(500).json({ message: 'Internal server error' });
			return;
		}
		const cleanFile = () =>
			fs.unlink(tempStoragePath() + tempFilename, () => null);

		if (
			typeof tagId !== 'string' ||
			typeof title !== 'string' ||
			typeof description !== 'string'
		) {
			res.status(400).json({ message: 'Invalid required fields' });
			cleanFile();
			return;
		}

		try {
			const tag = await getTagById(tagId);
			if (!tag) {
				res.status(400).json({ message: 'Invalid tagId' });
				cleanFile();
				return;
			}

			const fileExtension = path.extname(tempFilename).slice(1);

			// @ts-ignore
			const userId = req.user._id;

			const video: Video = {
				userId: new ObjectId(userId),
				title,
				description,
				tagId: new ObjectId(tagId),
				uploadDate: new Date(),
				fileExtension,
				upvotes: [],
			};

			const result = await createVideo(video);
			const videoId = result.insertedId;

			const tempFilePath = tempStoragePath() + tempFilename;
			const finalFilePath = `${videoStoragePath() + videoId}.${fileExtension}`;
			fs.renameSync(tempFilePath, finalFilePath);

			res.status(201).json({ message: 'Video uploaded successfully', videoId });
		} catch (error) {
			console.error('Error uploading video:', error);
			res.status(500).json({ message: 'Internal server error' });

			cleanFile();
		}
	},
);

router.get(
	'/',
	passport.authenticate('bearer', { session: false }),
	async (req, res) => {
		let page = Number(req.query.page ?? 1);
		let limit = Number(req.query.limit ?? 10);

		if (!Number.isInteger(page) || !Number.isInteger(limit)) {
			res.status(400).json({ message: 'Invalid page or limit' });
			return;
		}

		page = Math.max(page, 1);
		limit = Math.max(1, Math.min(limit, 100));

		// @ts-ignore
		const userId = req.user._id;

		try {
			const tags = await getAllVideos({
				page,
				limit,
				search: typeof req.query.query === 'string' ? req.query.query : null,
				tagId: typeof req.query.tag === 'string' ? req.query.tag : null,
				userId,
			});
			res.status(200).json(tags);
		} catch (error) {
			console.error('Error fetching videos:', error);
			res.status(500).json({ message: 'Internal server error' });
		}
	},
);

router.use('/play', express.static(videoStoragePath()));

router.post(
	'/:id/upvote',
	passport.authenticate('bearer', { session: false }),
	async (req, res) => {
		const { id } = req.params;

		// @ts-ignore
		const userId = req.user._id;

		try {
			const isSuccess = await upvoteVideo(id, userId);

			if (isSuccess) {
				res.status(200).json({ message: 'Video upvoted successfully' });
				return;
			}

			res.status(400).json({ message: 'Invalid parameters' });
		} catch (error) {
			console.error('Error upvoting video:', error);
			res.status(500).json({ message: 'Internal server error' });
		}
	},
);

router.delete(
	'/:id/upvote',
	passport.authenticate('bearer', { session: false }),
	async (req, res) => {
		const { id } = req.params;

		// @ts-ignore
		const userId = req.user._id;

		try {
			const isSuccess = await downvoteVideo(id, userId);

			if (isSuccess) {
				res.status(200).json({ message: 'Video downvoted successfully' });
				return;
			}

			res.status(400).json({ message: 'Invalid parameters' });
		} catch (error) {
			console.error('Error downvoting video:', error);
			res.status(500).json({ message: 'Internal server error' });
		}
	},
);

export default router;
