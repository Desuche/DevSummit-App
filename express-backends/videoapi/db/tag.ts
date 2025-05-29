import { getDatabase } from './connection';
import type { Tag } from '../models';
import { ObjectId } from 'mongodb';

export const TAG_COLLECTION_NAME = 'tags';

const collection = () => {
	const db = getDatabase();
	return db.collection<Tag>(TAG_COLLECTION_NAME);
};

export const getTagById = async (tagId: string) =>
	collection().findOne({ _id: new ObjectId(tagId) });

export const getAllTags = async () =>
	(await collection().find().toArray()).map(({ _id, name }) => ({
		id: _id,
		name,
	}));
