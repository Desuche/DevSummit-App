import { getDatabase } from './connection';
import type { Video } from '../models';
import { ObjectId } from 'mongodb';
import { USER_COLLECTION_NAME } from './user';
import { TAG_COLLECTION_NAME } from './tag';

const collection = () => {
	const db = getDatabase();
	return db.collection<Video>('videos');
};

export const createVideo = (video: Video) => collection().insertOne(video);

export const getAllVideos = async ({
	page,
	limit,
	search,
	tagId,
	userId,
}: {
	page: number;
	limit: number;
	search: string | null;
	tagId: string | null;
	userId: string;
}) => {
	const skip = (Number(page) - 1) * Number(limit);
	// biome-ignore lint/suspicious/noExplicitAny: This is a MongoDB query object
	const query: any = {};

	if (search) {
		query.$or = [
			{ name: { $regex: search, $options: 'i' } },
			{ description: { $regex: search, $options: 'i' } },
		];
	}

	if (tagId) {
		query.tagId = new ObjectId(tagId as string);
	}

	const videos = await collection()
		.aggregate([
			{ $match: query },
			{ $sort: { _id: -1 } },
			{ $skip: skip },
			{ $limit: limit },
			{
				$lookup: {
					from: USER_COLLECTION_NAME,
					localField: 'userId',
					foreignField: '_id',
					as: 'uploader',
				},
			},
			{ $unwind: '$uploader' },
			{
				$lookup: {
					from: TAG_COLLECTION_NAME,
					localField: 'tagId',
					foreignField: '_id',
					as: 'tag',
				},
			},
			{ $unwind: '$tag' },
			{
				$project: {
					id: '$_id',
					_id: 0,
					title: 1,
					description: 1,
					uploader: {
						id: '$uploader._id',
						_id: 0,
						name: 1,
					},
					tag: {
						id: '$tag._id',
						_id: 0,
						name: 1,
					},
					upvotes: { $size: '$upvotes' },
					fileExtension: 1,
					uploadDate: 1,
					hasUpvoted: { $in: [userId, '$upvotes'] },
				},
			},
			{ $sort: { upvotes: -1 } },
		])
		.toArray();

	const total = await collection().countDocuments(query);

	return {
		page,
		limit,
		total,
		videos,
	};
};

export const upvoteVideo = async (videoId: string, userId: string) => {
	const result = await collection().updateOne(
		{ _id: new ObjectId(videoId) },
		{ $addToSet: { upvotes: userId } },
	);

	return result.matchedCount !== 0;
};

export const downvoteVideo = async (videoId: string, userId: string) => {
	const result = await collection().updateOne(
		{ _id: new ObjectId(videoId) },
		{ $pull: { upvotes: userId } },
	);

	return result.matchedCount !== 0;
};
