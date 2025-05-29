import { ObjectId } from 'mongodb';

export type Event = {
    _id?: ObjectId,
    name: String,
    date: Date,
    description: String,
    location: String,
    latitude: number,
    longitude: number,
    organizer: String,
    attendees: ObjectId[],
}