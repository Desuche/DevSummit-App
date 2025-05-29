import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import { Server } from 'ws';
import chatRouter from './routes/chat';
import { chatWebSocketHandler} from './routes/chat';
import { connectToDatabase } from './db/connection';
const morgan = require('morgan');

var jwt = require('jsonwebtoken');
var passport = require('passport');
var BearerStrategy = require('passport-http-bearer').Strategy;
passport.use(new BearerStrategy(
  function (token: any, done: any) {
    jwt.verify(token, process.env.JWT_SECRET, function (err: any, decoded: any) {
      if (err) { 
        console.log(err);
        return done(null, false); }
      return done(null, decoded, { scope: "none" });
    });
  }
));

connectToDatabase();

const app = express();
app.use(morgan('combined'));
const PORT = process.env.PORT ?? 3000;
const portNumber = Number(PORT);
if (isNaN(portNumber)) {
	throw new Error('Invalid port number');
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/chat', chatRouter);

// app.use('/', express.static('storage'));

let server = app.listen(portNumber, '0.0.0.0', () => {
	console.log(`Server is running on http://0.0.0.0:${PORT}`);
});


// Create a WebSocket server
const wss = new Server({ server });

wss.on('connection', (ws, req) => {
  // Parse the URL to extract query parameters
  //@ts-ignore
  const { searchParams } = new URL(req.url, `http://${req.headers.host}`);
  console.log(searchParams);
  console.log(req.url);
  console.log(req.headers.host);

  const chatUserId = searchParams.get('chatUserId'); // Get chatUserId
  const token = searchParams.get('token'); // Get token
  const lastMessageId = searchParams.get('lastMessageId'); // Get lastMessageId
  console.log(searchParams);

  if (!token || !chatUserId) {
    console.error('Token or chatUserId is missing');
      ws.close(); // Close connection if token or chatUserId is missing
      return;
  }


  // Verify the token
  //@ts-ignore
  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
      if (err) {
          console.error('Token verification failed:', err);
          ws.close(); // Close connection if token is invalid
          return;
      }

      // Attach user information to the request 
      //@ts-ignore
      req.user = decoded;

      // Call the chat WebSocket handler with the extracted chatUserId
      chatWebSocketHandler(ws, req, chatUserId, lastMessageId);
  });
});

