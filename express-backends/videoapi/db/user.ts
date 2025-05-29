import type { ObjectId } from 'mongodb';
import type { User } from '../models';
import { getDatabase } from './connection';

export const USER_COLLECTION_NAME = 'users';

const collection = () => {
	const db = getDatabase();
	return db.collection<User>(USER_COLLECTION_NAME);
};

// export const createEmptyUser = async () => {
//     let user: User = { createdAt: new Date() }
//     const db = getDatabase();
//     const result = await collection().insertOne(user);
//     if (result.insertedId) {
//         return result.insertedId;
//     } else {
//         throw new Error('Could not create user');
//     }
// }

export const createUser = async (name: string, email: string) => {
	const user: User = { name: name, email: email, createdAt: new Date() };
	const result = await collection().insertOne(user);
	if (result.insertedId) {
		return result.insertedId;
	}

	throw new Error('Could not create user');
};

export const getUserById = async (userId: ObjectId) => {
	return await collection().findOne({ _id: userId });
};
