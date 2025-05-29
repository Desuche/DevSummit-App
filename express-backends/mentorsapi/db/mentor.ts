// Import necessary modules and types
import { getDatabase } from "./connection";
import { Mentor, Connection, ConnectionStatus } from "../models/mentor";
import { ObjectId, UUID } from "mongodb";
import { stat } from "fs";
import { getUserById } from "./user"; // Assuming this function gets the user details by ID


const mentorCollection = () => getDatabase().collection<Mentor>("mentors");
const connectionCollection = () => getDatabase().collection<Connection>("connections");

// Create a mentor profile
export const createMentor = async (mentor: Mentor) => {
    const result = await mentorCollection().insertOne(mentor);
    return result.insertedId;
};

// Get all mentors with connection status for a user
export const getAllMentorsWithStatus = async (userId: ObjectId) => {
    const mentors = await mentorCollection().find().toArray();
    const results = [];

    for (const mentor of mentors) {
        // Skip the current user
        if (mentor.userId.equals(userId)) continue;

        // Fetch the name from the user table
        const user = await getUserById(mentor.userId);
        if (!user) continue; // Skip if user is not found

        // Find connection status
        const connection = await connectionCollection().findOne({
            $or: [
                { userId, mentorId: mentor.userId },
                { userId: mentor.userId, mentorId: userId },
            ],
        });

        let status: ConnectionStatus = ConnectionStatus.none;
        if (connection) {
            if (connection.userId.equals(userId) && connection.status === ConnectionStatus.pending) {
                status = ConnectionStatus.pending;
            } else if (connection.mentorId.equals(userId) && connection.status === ConnectionStatus.pending) {
                status = ConnectionStatus.wait;
            } else if (connection.status === ConnectionStatus.accepted) {
                status = ConnectionStatus.accepted;
            }
        }

        // Add mentor details with name and status
        results.push({
            ...mentor,
            name: user.name,
            status,
        });
    }

    return results;
};




export const searchMentorsWithStatus = async (
    userId: ObjectId,
    searchQuery: string
) => {
    const db = getDatabase();

    // Step 1: Fetch all matching users (name search)
    const matchingUsers = await db.collection('users')
        .find({ name: { $regex: searchQuery, $options: 'i' } })
        .toArray();

    const matchingUserIds = matchingUsers.map(user => user._id);

    // Step 2: Fetch mentors that match bio or fieldOfInterest or belong to matching users
    const mentors = await db.collection('mentors')
        .find({
            $or: [
                { bio: { $regex: searchQuery, $options: 'i' } },
                { fieldOfInterest: { $regex: searchQuery, $options: 'i' } },
                { userId: { $in: matchingUserIds } }
            ]
        })
        .toArray();

    const results = [];

    // Step 3: Add connection status and name for each mentor
    for (const mentor of mentors) {
        // Fetch the user details for the mentor
        const user = matchingUsers.find(u => u._id.equals(mentor.userId)) ||
                     await db.collection('users').findOne({ _id: mentor.userId });

        if (!user || mentor.userId.equals(userId)) continue;

        // Find connection status
        const connection = await db.collection('connections').findOne({
            $or: [
                { userId, mentorId: mentor.userId },
                { userId: mentor.userId, mentorId: userId }
            ]
        });

        let status: ConnectionStatus = ConnectionStatus.none;
        if (connection) {
            if (connection.userId.equals(userId) && connection.status === ConnectionStatus.pending) {
                status = ConnectionStatus.pending;
            } else if (connection.mentorId.equals(userId) && connection.status === ConnectionStatus.pending) {
                status = ConnectionStatus.wait;
            } else if (connection.status === ConnectionStatus.accepted) {
                status = ConnectionStatus.accepted;
            }
        }

        results.push({
            ...mentor,
            name: user?.name || 'Unknown',
            status
        });
    }

    return results;
};








// Get mentor by userId
export const getMentorByUserId = async (userId: ObjectId) => {
    return await mentorCollection().findOne({ userId });
};


export const getMentorById = async (id: string) => {
    if (!ObjectId.isValid(id)) {
        throw new Error("Invalid Mentor ID.");
    }

    const mentor = await mentorCollection().findOne({ _id: new ObjectId(id) });

    if (!mentor) {
        throw new Error("Mentor not found.");
    }

    return mentor;
};


// Create or toggle a connection request
export const toggleConnection = async (userId: ObjectId, mentorId: ObjectId) => {
    // Check for an existing connection
    const existingConnection = await connectionCollection().findOne({
        userId,
        mentorId,
    });

    if (existingConnection) {
        if (existingConnection.status === ConnectionStatus.pending) {
            // Cancel the existing pending connection
            const result = await connectionCollection().deleteOne({
                _id: existingConnection._id,
            });
            return { action: "deleted", success: result.deletedCount > 0 };
        } else if (existingConnection.status === ConnectionStatus.rejected) {
            // Reset the rejected connection to pending
            const success = await updateConnectionStatus(existingConnection._id, ConnectionStatus.pending);
            return { action: "reset", success };
        }
    } else {
        // Create a new connection if none exists
        const connection: Connection = {
            userId,
            mentorId,
            status: ConnectionStatus.pending,
            createdAt: new Date(),
        };
        const result = await connectionCollection().insertOne(connection);
        return { action: "created", success: !!result.insertedId };
    }

    return { action: "none", success: false };
};


// Get pending connections for a mentor
// export const getPendingConnections = async (mentorId: ObjectId) => {
//     return await connectionCollection()
//         .find({ mentorId, status: ConnectionStatus.pending })
//         .toArray();
// };


export const getPendingConnections = async (userId: ObjectId) => {
    const db = getDatabase();

    const connections = await db.collection('connections')
        .aggregate([
            {
                $match: {
                    $or: [
                        { mentorId: userId, status: ConnectionStatus.pending },
                        { userId, status: ConnectionStatus.pending }
                    ]
                }
            },
            {
                $addFields: {
                    otherUserId: {
                        $cond: {
                            if: { $eq: ['$mentorId', userId] },
                            then: '$userId',
                            else: '$mentorId'
                        }
                    }
                }
            },
            {
                $lookup: {
                    from: 'users', // Name of the users collection
                    localField: 'otherUserId',
                    foreignField: '_id',
                    as: 'otherUserDetails'
                }
            },
            {
                $addFields: {
                    otherUserName: { $arrayElemAt: ['$otherUserDetails.name', 0] }
                }
            },
            {
                $project: {
                    _id: 1, // Connection ID
                    userId: 1,
                    mentorId: 1,
                    status: 1,
                    createdAt: 1,
                    otherUserName: 1 // The name of the other user
                }
            }
        ])
        .toArray();

    return connections;
};


// Update connection status
export const updateConnectionStatus = async (connectionId: ObjectId, status: ConnectionStatus) => {
    const result = await connectionCollection().updateOne(
        { _id: connectionId },
        { $set: { status } }
    );
    return result.modifiedCount > 0;
};

// Get active connections for a user or mentor
export const getActiveConnections = async (userId: ObjectId) => {
    const connections = await connectionCollection()
        .find({
            $or: [
                { userId, status: ConnectionStatus.accepted },
                { mentorId: userId, status: ConnectionStatus.accepted },
            ],
        })
        .toArray();

    const results = [];

    for (const connection of connections) {
        // Determine the other user's ID
        const otherUserId = connection.userId.equals(userId) ? connection.mentorId : connection.userId;

        // Try to fetch the mentor profile using the other user's ID
        const mentor = await mentorCollection().findOne({ userId: otherUserId });

        if (mentor) {
            // If mentor is found, include their details
            const user = await getUserById(otherUserId);
            if (!user) continue; // Skip if the user is not found

            results.push({
                ...mentor, // Include all mentor fields
                name: user.name || "Unknown", // Add the user's name
                status: ConnectionStatus.accepted, // Set the status as accepted
            });
        } else {
            // If not found in the mentor collection, fetch from the users collection
            const user = await getUserById(otherUserId);
            if (!user) continue; // Skip if the user is not found

            // Construct a response with empty mentor fields
            results.push({
                _id: user._id, // No mentor _id
                userId: otherUserId,
                fieldOfInterest: "", // Empty field
                experience: "0", // Default to 0 for experience
                bio: "", // Empty bio
                tags: [], // Empty tags
                name: user.name || "Unknown", // Add the user's name
                status: ConnectionStatus.accepted, // Set the status as accepted
            });
        }
    }

    return results;
};



// Get mentor with tag names
export const getMentorWithTags = async (mentorId: ObjectId) => {
    const mentor = await mentorCollection().findOne({ _id: mentorId });
    if (!mentor) return null;

    const db = getDatabase();
    const tagCollection = db.collection("tags");
    const tags = await tagCollection.find({ _id: { $in: mentor.tags } }).toArray();

    return { ...mentor, tags: tags.map((tag) => tag.name) };
};

// Delete a connection (handles both directions)
export const deleteConnection = async (userId: ObjectId, mentorId: ObjectId) => {
    const result = await connectionCollection().deleteOne({
        $or: [
            { userId, mentorId },
            { userId: mentorId, mentorId: userId },
        ],
    });
    console.log(userId)
    console.log(mentorId)
    return result.deletedCount > 0;
};

// Get all accepted connections for a user
export const getAcceptedMentors = async (userId: ObjectId) => {
    const connections = await connectionCollection()
        .find({ 
            $or: [
                { userId, status: ConnectionStatus.accepted },
                { mentorId: userId, status: ConnectionStatus.accepted },
            ]
        })
        .toArray();

    const results = [];
    for (const connection of connections) {
        const mentorId = connection.userId.equals(userId) ? connection.mentorId : connection.userId;

        const mentor = await mentorCollection().findOne({ userId: mentorId });
        if (mentor) {
            results.push({
                ...mentor,
                status: ConnectionStatus.accepted,
            });
        }
    }

    return results;
};


