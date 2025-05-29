import express from 'express';
import cors from 'cors';
// import 'dotenv/config';
// import authRouter from './routes/auth';
// import eventRouter from './routes/event';

import bodyParser from "body-parser";

import userRoutes from "./routes/user";

import mentorRoutes from "./routes/mentor";
import dotenv from "dotenv";
dotenv.config(); // Load .env file



import { connectToDatabase } from './db/connection';

var jwt = require('jsonwebtoken');
var passport = require('passport');
var BearerStrategy = require('passport-http-bearer').Strategy;
passport.use(new BearerStrategy(
  function (token: any, done: any) {
    jwt.verify(token, process.env.JWT_SECRET, function (err: any, decoded: any) {
      if (err) { return done(null, false); }
      return done(null, decoded, { scope: "none" });
    });
  }
));

connectToDatabase();

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));


const PORT = process.env.PORT ?? 3000;
const portNumber = Number(PORT);
if (isNaN(portNumber)) {
	throw new Error('Invalid port number');
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// app.use('/auth', authRouter);
// app.use('/event', eventRouter);

app.use("/mentors", mentorRoutes);
app.use("/users", userRoutes);



app.listen(portNumber, '0.0.0.0', () => {
	console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
