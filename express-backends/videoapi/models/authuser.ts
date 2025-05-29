import type { ObjectId } from 'mongodb';

export enum PlatformName {
	Phone = 'phone',
	Facebook = 'facebook',
	Google = 'google',
}

export type AuthUser = {
	_id?: ObjectId;
	userId: ObjectId;
	platformUserId: string;
	platformName: PlatformName;
};
