const WebSocket = require("ws");
const readline = require("readline");

// Function to start WebSocket client
function startWebSocketClient(wsBaseUrl, chatUserId, authToken, lastMessageId) {
  let wsUrl = `${wsBaseUrl}?chatUserId=${chatUserId}&token=${authToken}`;
  if (lastMessageId) {
    wsUrl = `${wsUrl}&lastMessageId=${lastMessageId}`;
  }
  const ws = new WebSocket(wsUrl);

  // Set up readline for user input
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  ws.on("open", () => {
    console.log("WebSocket connection established");
    inputLoop(); // Start the input loop when the connection is open
  });

  ws.on("message", (data) => {
    data = data.toString();
    let parsedData = JSON.parse(data);
    console.log("Message from server:", parsedData);
  });

  ws.on("error", (error) => {
    console.error("WebSocket error:", error);
  });

  ws.on("close", () => {
    console.log("WebSocket connection closed");
    rl.close(); // Close the readline interface when the connection closes
  });

  function inputLoop() {
    rl.question('Enter message to send (type "quit" to exit): ', (input) => {
      if (input.toLowerCase() === "quit") {
        ws.close(); // Close the WebSocket connection on quit
        console.log("Exiting...");
        return;
      }

      sendMessage(input); // Send the input message
      inputLoop(); // Recursive call for the next input
    });
  }

  function sendMessage(message) {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(message);
      console.log("Sent:", message);
    } else {
      console.error("WebSocket is not open. Ready state:", ws.readyState);
    }
  }
}

// Main function to read parameters and run the WebSocket client
function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });

  const defaultWsUrl = "ws://0.0.0.0:3000/chat";
  const defaultChatUserId = "673d7bbe371d2f79e5a09808";
  const defaultAuthToken =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI2NzQ3ZWZlMzQxMmMxZWE3ZjJmYmY4OTgiLCJuYW1lIjoiSGFyYWthIEJhcmFrYSIsImVtYWlsIjoiSGFyYWthQGdtYWlsLmNvbSIsImNyZWF0ZWRBdCI6IjIwMjQtMTEtMjhUMDQ6MjE6NTUuMzA5WiIsImlhdCI6MTczMjc3NTEzNn0.KM7f8EqoVpC25aVq3AfiuidU1ID4CJzGOBEW3cmjKq8"; // Set a default or placeholder token

  const user2ID = "6747efe3412c1ea7f2fbf898";
  const user2Token =
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJPbmxpbmUgSldUIEJ1aWxkZXIiLCJpYXQiOjE3MzI4OTU3MTgsImV4cCI6MTc2NDQzMTcxOCwiYXVkIjoid3d3LmV4YW1wbGUuY29tIiwic3ViIjoianJvY2tldEBleGFtcGxlLmNvbSIsIl9pZCI6IjY3M2Q3YmJlMzcxZDJmNzllNWEwOTgwOCIsIlN1cm5hbWUiOiJSb2NrZXQiLCJFbWFpbCI6Impyb2NrZXRAZXhhbXBsZS5jb20iLCJSb2xlIjpbIk1hbmFnZXIiLCJQcm9qZWN0IEFkbWluaXN0cmF0b3IiXX0.tgkRu2QOnPv_yaNZO_SOmscPmL2Xfs5anEaeEEesZxs";

  rl.question(`Enter WebSocket URL (default: ${defaultWsUrl}): `, (wsUrl) => {
    wsUrl = wsUrl.trim() || defaultWsUrl; // Use default if empty

    rl.question(
      `Enter chat user ID (default: ${defaultChatUserId}): `,
      (chatUserId) => {
        if (chatUserId === "2") {
          chatUserId = user2ID;
        }
        chatUserId = chatUserId.trim() || defaultChatUserId; // Use default if empty

        rl.question(
          `Enter authentication token (default: ${defaultAuthToken}): `,
          (authToken) => {
            if (authToken === "2") {
              authToken = user2Token;
            }
            authToken = authToken.trim() || defaultAuthToken; // Use default if empty

            rl.question(`Enter last message ID : `, (lastMessageId) => {
              if (lastMessageId != "") {
                lastMessageId = lastMessageId.trim();
                // Start the WebSocket client with the collected parameters
                startWebSocketClient(
                  wsUrl,
                  chatUserId,
                  authToken,
                  lastMessageId
                );
                // Do not close the readline interface here; it will be closed upon WebSocket disconnection
              } else {
                // Start the WebSocket client with the collected parameters
                startWebSocketClient(wsUrl, chatUserId, authToken, "");
                // Do not close the readline interface here; it will be closed upon WebSocket disconnection
              }
            });
          }
        );
      }
    );
  });
}

// Run the main function
main();
