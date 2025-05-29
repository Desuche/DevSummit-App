import { ObjectId } from "mongodb";

// Mentor model
export type Mentor = {
    _id?: ObjectId;
    userId: ObjectId; // Links to the user table
    fieldOfInterest: string;
    experience: number;
    bio: string;
    tags: ObjectId[]; // Array of ObjectIds referencing tags
};

// Connection model for mentor-user connections
export type Connection = {
    _id?: ObjectId;
    userId: ObjectId;
    mentorId: ObjectId;
    status: ConnectionStatus; // Connection status
    createdAt: Date;
};

export enum ConnectionStatus {
    none = "none",  
    pending = "pending",
    accepted = "accepted",
    rejected = "rejected",
    wait = "waiting to accept",
};
