import express, { Request, Response } from "express";
import { getUserById } from "../db/user";
import { ObjectId } from "mongodb";

const router = express.Router();

/**
 * Get user details by userId
 */
// @ts-ignore
router.get("/:userId", async (req, res) => {
    const { userId } = req.params;

    // Validate userId
    if (!ObjectId.isValid(userId)) {
        return res.status(400).json({ message: "Invalid userId" });
    }

    try {
        const user = await getUserById(new ObjectId(userId));

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        // Send user details (only name in this example)
        return res.status(200).json({ name: user.name });
    } catch (error) {
        console.error("Error fetching user:", error);
        return res.status(500).json({ message: "Internal server error" });
    }
});

export default router;
