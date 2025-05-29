import type { ObjectId } from 'mongodb';

export type Event = {
	_id?: ObjectId;
	name: string;
	date: Date;
	description: string;
	location: string;
	latitude: number;
	longitude: number;
	organizer: string;
	attendees: ObjectId[];
};
