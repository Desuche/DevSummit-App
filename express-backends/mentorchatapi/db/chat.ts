import { ObjectId } from "mongodb";
import { ChatMessage } from "../models/chat";
import { getDatabase } from "./connection";

const collection = () => {
    const db = getDatabase();
    return db.collection<ChatMessage>('chats');
}


//* Get all chat messages by connection id (sorted by creation time using ObjectId's intrinsicly sorted property)
export const getChatMessagesByConnectionId = async (connectionId: ObjectId): Promise<ChatMessage[]> => {
    const messages = await collection().find({ 
        connectionId: connectionId
    }).sort({ _id: 1 }).toArray();
    return messages;
};

// Get NEW chat messages by connection id and last message id (sorted by creation time using ObjectId's intrinsicly sorted property)
export const getNewChatMessages = async (connectionId: ObjectId, lastMessageId: ObjectId): Promise<ChatMessage[]> => {
    const messages = await collection().find({
        connectionId: connectionId,
        _id: { $gt: lastMessageId }
    }).sort({ _id: 1 }).toArray();
    return messages;
};

// Send a new chat message
export const sendChatMessage = async (connectionId: ObjectId, message: string, senderId: ObjectId): Promise<ChatMessage> => {
    const newMessage: ChatMessage = {
        connectionId: connectionId,
        message: message,
        senderId: senderId,
        timestamp: new Date()
    };
    await collection().insertOne(newMessage);
    return newMessage;
};