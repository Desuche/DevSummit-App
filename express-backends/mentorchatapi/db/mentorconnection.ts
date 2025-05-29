import { ObjectId } from "mongodb";
import { Connection, ConnectionStatus } from "../models/mentorconnection";
import { getDatabase } from "./connection";

const collection = () => {
    const db = getDatabase();
    return db.collection<Connection>('connections');
}

export const getConnectionIdByParticipantsId = async (user1: ObjectId, user2: ObjectId) => {
    const coll = await collection().findOne({
        $or: [
            { userId: user1, mentorId: user2 },
            { userId: user2, mentorId: user1 }
        ]
    });

    if (coll) {
        return coll._id;
    } else {
        throw new Error('Connection not found');
    }
};

export const isAllowedToChat = async (user1: ObjectId, user2: ObjectId) => {
    try {
        const connectionId = await getConnectionIdByParticipantsId(user1, user2);
        const coll = await collection().findOne({ _id: connectionId, status: ConnectionStatus.accepted });
        if (coll) {
            return true;
        } else {
            return false;
        }
    } catch (error) {
        return false;
    }
}