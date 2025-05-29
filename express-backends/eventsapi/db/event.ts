import { getDatabase } from "./connection";
import { ObjectId } from 'mongodb';
import { Event } from '../models/event';

const collection = () => {
    return getDatabase().collection('events');
}

export const createEvent = async (event: Event) => {
    const result = await collection().insertOne(event);
    return result.insertedId;
}

export const getEventById = async (id: ObjectId) => {
    return await collection().findOne({ _id: id });
}

export const getEventsByDate = async (date: Date) => {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);

    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    return await collection().find({ date: { $gte: start, $lte: end } }).toArray();
}

export const getEventsByAttendee = async (userId: ObjectId) => {
    return await collection().find({ attendees: userId }).toArray();
}

export const getAllEvents = async () => {  
    return await collection().find().toArray();
}

export const registerForEvent = async (eventId: ObjectId, userId: ObjectId) => {
    const result = await collection().updateOne(
        { _id: eventId },
        { $addToSet: { attendees: userId } } // $addToSet ensures idempotency
    );
    return result.modifiedCount > 0;
}

export const unregisterForEvent = async (eventId: ObjectId, userId: ObjectId) => {
    const result = await collection().updateOne(
        { _id: eventId },
        //@ts-ignore
        { $pull: { attendees: userId } }
    );
    return result.modifiedCount > 0;
}