import { ObjectId } from "mongodb";
import { User } from "../models/user";
import { getDatabase } from "./connection";

const collection = () => {
    const db = getDatabase();
    return db.collection<User>('users');
}

export const createEmptyUser = async () => {
    let user: User = { createdAt: new Date() }
    const db = getDatabase();
    const result = await collection().insertOne(user);
    if (result.insertedId) {
        return result.insertedId;
    } else {
        throw new Error('Could not create user');
    }
}

export const createUser = async (name: string, email:string) => {
    let user: User = { name:name, email:email, createdAt: new Date() }
    const db = getDatabase();
    const result = await collection().insertOne(user);
    if (result.insertedId) {
        return result.insertedId;
    } else {
        throw new Error('Could not create user');
    }
}


export const getUserById = async (userId: ObjectId) => {
    return await collection().findOne({ _id: userId });
}