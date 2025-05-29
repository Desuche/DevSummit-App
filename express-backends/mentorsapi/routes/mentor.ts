import express from "express";
import passport from "passport";
import {
    createMentor,
    getAllMentorsWithStatus,
    toggleConnection,
    getPendingConnections,
    updateConnectionStatus,
    getActiveConnections,
    getMentorByUserId,
    deleteConnection,
    getAcceptedMentors,
    getMentorById,
    searchMentorsWithStatus
} from "../db/mentor";
import { ObjectId } from "mongodb";
import { ConnectionStatus } from "../models/mentor";

const router = express.Router();

// Check if the user is a mentor
router.get("/is-mentor", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);

        const mentorProfile = await getMentorByUserId(userId);
        res.status(200).json({ isMentor: !!mentorProfile });
    } catch (error) {
        console.error("Error checking mentor status:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

// Get all mentors with connection status
router.get("/", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = req.user._id;

        const mentors = await getAllMentorsWithStatus(new ObjectId(userId));
        res.status(200).json(mentors);
    } catch (error) {
        console.error("Error fetching mentors:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

// Get active connections for the logged-in user
router.get("/connections", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);

        const activeConnections = await getActiveConnections(userId);
        res.status(200).json(activeConnections);
    } catch (error) {
        console.error("Error fetching active connections:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});


// @ts-ignore
router.get("/search", passport.authenticate("bearer", { session: false }),async (req, res) => {
        try {
            // @ts-ignore
            const userId = new ObjectId(req.user._id);
            const { query } = req.query;

            if (!query || typeof query !== "string") {
                return res.status(400).json({ message: "Search query is required." });
            }

            const mentors = await searchMentorsWithStatus(userId, query);
            res.status(200).json(mentors);
        } catch (error) {
            console.error("Error searching mentors:", error);
            res.status(500).json({ message: "Internal server error" });
        }
    }
);




// Get connected mentors (accepted connections only)
router.get("/connected", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);

        const connectedMentors = await getActiveConnections(userId);
        res.status(200).json(connectedMentors);
    } catch (error) {
        console.error("Error fetching connected mentors:", error);
        res.status(500).json({ message: "Internal server error." });
    }
});

// Create a mentor profile
router.post("/register", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);
        const { fieldOfInterest, experience, bio, tags } = req.body;

        if (!fieldOfInterest || !experience || !bio || !Array.isArray(tags)) {
            res.status(400).json({ message: "All fields are required, including tags." });
            return;
        }

        const mentor = {
            userId,
            fieldOfInterest,
            experience,
            bio,
            tags: tags.map((tag: string) => new ObjectId(tag)),
        };

        const mentorId = await createMentor(mentor);
        res.status(201).json({ mentorId });
    } catch (error) {
        console.error("Error creating mentor profile:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

// Toggle connection with a mentor
router.post("/connect", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);
        const { mentorId } = req.body;

        if (!mentorId) {
            res.status(400).json({ message: "Mentor ID is required." });
            return;
        }

        const result = await toggleConnection(userId, new ObjectId(mentorId));

        if (result.success) {
            const action = result.action;
            res.status(200).json({
                action,
                message:
                    action === "created"
                        ? "Connection request sent."
                        : "Connection request canceled.",
            });
        } else {
            res.status(400).json({ message: "No action performed." });
        }
    } catch (error) {
        console.error("Error handling connection request:", error);
        res.status(500).json({ message: "Internal server error." });
    }
});

// Get pending requests for a mentor
router.get("/requests", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);

        const requests = await getPendingConnections(userId);
        res.status(200).json(requests);
    } catch (error) {
        console.error("Error fetching pending requests:", error);
        res.status(500).json({ message: "Internal server error" });
    }
});

// Update connection status
router.put("/requests/:id", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        const { status } = req.body;
        const { id } = req.params;

        if (!status || ![ConnectionStatus.accepted, ConnectionStatus.rejected].includes(status)) {
            res.status(400).json({ message: "Invalid status." });
            return;
        }

        const success = await updateConnectionStatus(new ObjectId(id), status as ConnectionStatus);

        if (success) {
            res.status(200).json({ message: "Connection status updated." });
        } else {
            res.status(400).json({ message: "Failed to update connection status." });
        }
    } catch (error) {
        console.error("Error updating connection status:", error);
        res.status(500).json({ message: "Internal server error." });
    }
});



// Cancel a connection
router.delete("/connect", passport.authenticate("bearer", { session: false }), async (req, res) => {
    //@ts-ignore
    const userId = new ObjectId(req.user._id);
        const { mentorId } = req.body;
        console.log(userId);
        console.log(mentorId);
    
    try {
        // @ts-ignore
        const userId = new ObjectId(req.user._id);
        const { mentorId } = req.body;
        console.log(userId);
        console.log(mentorId);

        if (!mentorId) {
            res.status(400).json({ message: "Mentor ID is required." });
            return;
        }

        const success = await deleteConnection(userId, new ObjectId(mentorId));
        if (success) {
            res.status(200).json({ message: "Connection canceled successfully." });
        } else {
            res.status(400).json({ message: "Failed to cancel the connection." });
        }
    } catch (error) {
        console.error("Error canceling connection:", error);
        res.status(500).json({ message: "Internal server error." });
    }
});


// Fetch Mentor Details by ID
router.get("/:id", passport.authenticate("bearer", { session: false }), async (req, res) => {
    try {
        const mentorId = req.params.id;

        const mentor = await getMentorById(mentorId);
        res.status(200).json(mentor);
    } catch (error) {
        if (error instanceof Error) {
            // Explicitly narrow down the error type
            if (error.message === "Invalid Mentor ID.") {
                res.status(400).json({ message: error.message });
            } else if (error.message === "Mentor not found.") {
                res.status(404).json({ message: error.message });
            } else {
                console.error("Error fetching mentor details:", error.message);
                res.status(500).json({ message: "Internal server error." });
            }
        } else {
            // Handle cases where the error is not an instance of Error
            console.error("Unexpected error type:", error);
            res.status(500).json({ message: "An unexpected error occurred." });
        }
    }
});



export default router;
