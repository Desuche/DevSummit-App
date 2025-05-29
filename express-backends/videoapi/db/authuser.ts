import type { ObjectId } from 'mongodb';
import type { AuthUser, PlatformName } from '../models/authuser';
import { getDatabase } from './connection';

const collection = () => {
	const db = getDatabase();
	return db.collection<AuthUser>('authusers');
};

export const getUserIdByPlatformAndPlatformUserID = async (
	platformName: PlatformName,
	platformUserId: string,
) => {
	const user = await collection().findOne({ platformUserId, platformName });
	if (!user) {
		return null;
	}
	return user.userId;
};

export const createAuthUser = async (
	userId: ObjectId,
	platformUserId: string,
	platformName: PlatformName,
) => {
	const result = await collection().insertOne({
		userId,
		platformUserId,
		platformName,
	});
	if (result.insertedId) {
		return result.insertedId;
	}
	throw new Error('Could not create user');
};
