import type { ObjectId } from 'mongodb';

export type Video = {
	_id?: ObjectId;
	userId: ObjectId;
	title: string;
	description: string;
	tagId: ObjectId;
	uploadDate: Date;
	fileExtension: string;
	upvotes: string[];
};
