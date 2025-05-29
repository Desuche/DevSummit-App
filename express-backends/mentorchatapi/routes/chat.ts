import express from "express";
const passport = require("passport");
import { ObjectId } from "mongodb";
import {
  getConnectionIdByParticipantsId,
  isAllowedToChat,
} from "../db/mentorconnection";
import {
  getChatMessagesByConnectionId,
  getNewChatMessages,
  sendChatMessage,
} from "../db/chat";
const router = express.Router();

/*
 * Regular REST API endpoints for fetching historical chat.
 */

router.get(
  "/all/:chatUserId",
  passport.authenticate("bearer", { session: false }),
  async (req, res) => {
    let chatUserId: ObjectId;

    try {
      chatUserId = new ObjectId(req.params.chatUserId);
    } catch (error) {
      res.status(400).json({ error: "Invalid chatUserId" });
      return;
    }

    //@ts-ignore
    const currentUserId = req.user._id;
    try {
      const connectionId = await getConnectionIdByParticipantsId(
        currentUserId,
        chatUserId
      );
      const messages = await getChatMessagesByConnectionId(connectionId);
      res.json(messages);
    } catch (error) {
      res
        .status(500)
        .json({ error: "An error occurred while fetching chat messages" });
    }
  }
);

router.get(
  "/new/:chatUserId",
  passport.authenticate("bearer", { session: false }),
  async (req, res) => {
    let chatUserId: ObjectId;
    let lastMessageId: ObjectId;

    try {
      chatUserId = new ObjectId(req.params.chatUserId);
      lastMessageId = new ObjectId(req.query.lastMessageId as string);
    } catch (error) {
      res
        .status(400)
        .json({ error: "Invalid chatUserId or Invalid lastMessageId" });
      return;
    }

    //@ts-ignore
    const currentUserId = req.user._id;
    try {
      const connectionId = await getConnectionIdByParticipantsId(
        currentUserId,
        chatUserId
      );
      const messages = await getNewChatMessages(connectionId, lastMessageId);
      res.json(messages);
    } catch (error) {
      res
        .status(500)
        .json({ error: "An error occurred while fetching new chat messages" });
    }
  }
);

/**
 * WebSocket code for sending and receiving chat messages.
 */

// Active WebSocket connections
const connections: { [key: string]: any[] } = {};

/**
 * Handles WebSocket connections for chat functionality.
 *
 * This function is triggered when a new WebSocket connection is established.
 * It validates the user and sets up message handling for the chat session.
 *
 * @param {WebSocket} ws - The WebSocket connection object for the client.
 * @param {Request} req - The HTTP request object associated with the WebSocket connection.
 * @param {string} chatUserIdString - The ID of the chat user to whom messages will be sent.
 *
 * The function performs the following steps:
 * 1. Extracts and validates the current user ID and the chat user ID from the request.
 * 2. Checks if the current user is allowed to chat with the specified user.
 * 3. Retrieves the connection ID based on the participant IDs.
 * 4. Sets up event listeners for incoming messages and connection closure:
 *    - On receiving a message, it broadcasts the message to other connected clients in the same chat.
 *    - On connection closure, it removes the client from the active connections list.
 * 5. Sends the previous chat messages to the newly connected client.
 *
 * If any validation fails or an error occurs during the process, the WebSocket connection is closed.
 */

export async function chatWebSocketHandler(
  ws: any,
  req: any,
  chatUserIdString: string,
  lastMessageId: string | null
) {
  //@ts-ignore
  let currentUserId: ObjectId;
  let chatUserId: ObjectId;

  try {
    currentUserId = new ObjectId(req.user._id);
    chatUserId = new ObjectId(chatUserIdString);
  } catch (error) {
    console.error("Invalid user ID:", error);
    ws.close();
    return;
  }

  let allowedToChat = await isAllowedToChat(currentUserId, chatUserId);
  if (!allowedToChat) {
    console.error(`Users ${currentUserId} and ${chatUserId} are not allowed to chat`);
    ws.close();
    return;
  }

  getConnectionIdByParticipantsId(currentUserId, chatUserId)
    .then((connectionObjectId) => {
      var connectionId = connectionObjectId.toHexString();
      if (!connections[connectionId]) {
        connections[connectionId] = [];
      }
      connections[connectionId].push(ws);

      ws.on("message", async (receivedMessage: string) => {
        let message = Buffer.isBuffer(receivedMessage)
          ? receivedMessage.toString()
          : receivedMessage;
        console.log("Received message:", message);
        try {
          let newMessage = await sendChatMessage(
            connectionObjectId,
            message,
            currentUserId
          );
          connections[connectionId].forEach((client) => {
            if (client.readyState === client.OPEN) {
              client.send(JSON.stringify([newMessage]));
            }
          });
        } catch (error) {
          console.error("Error while sending chat message:", error);
        }
      });

      ws.on("close", () => {
        connections[connectionId] = connections[connectionId].filter(
          (client) => client !== ws
        );
      });

      let lastMessageObjectId: ObjectId | null = null;
      console.log(`last message: ${lastMessageId}`)
      try {
        if (lastMessageId) {
          lastMessageObjectId = new ObjectId(lastMessageId as string);
        }
      } catch (error) {
        console.error("Invalid lastMessageId:", error);
      }

      if (lastMessageObjectId != null) {
        console.log("Fetching new chat messages...");
        getNewChatMessages(connectionObjectId, lastMessageObjectId)
          .then((messages) => {
            console.log("Sending new chat messages:", messages);
            ws.send(JSON.stringify(messages));
          })
          .catch((error) => {
            console.error("Error while fetching new chat messages:", error);
          });
      } else {
        console.log("Fetching chat messages...");
        getChatMessagesByConnectionId(connectionObjectId)
          .then((messages) => {
            console.log("Sending chat messages:", messages);
            ws.send(JSON.stringify(messages));
          })
          .catch((error) => {
            console.error("Error while fetching chat messages:", error);
          });
      }
    })
    .catch((error) => {
      console.error("Error while fetching connectionId:", error);
      ws.close();
    });
}

export default router;
