import { ObjectId } from "mongodb";

export type Connection = {
    _id?: ObjectId;
    userId: ObjectId;
    mentorId: ObjectId;
    status: ConnectionStatus; // Connection status
    createdAt: Date;
}

export enum ConnectionStatus{
    pending = "pending",
    accepted = "accepted",
    rejected = "rejected",
    wait = "waiting to accept"
};