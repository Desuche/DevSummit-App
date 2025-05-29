import { ObjectId } from "mongodb";

export type ChatMessage = {
    _id?: ObjectId;
    connectionId: ObjectId; // Reference to the Connection
    senderId: ObjectId; // User who sent the message
    message: string; // Message content
    timestamp: Date; // When the message was sent
};