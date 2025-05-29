import express from 'express';
import cors from 'cors';
import 'dotenv/config';
import authRouter from './routes/auth';
import eventRouter from './routes/event';
7;
import videoRouter from './routes/video';
import tagRouter from './routes/tag';
import { connectToDatabase } from './db/connection';
import jwt from 'jsonwebtoken';
import passport from 'passport';
import { Strategy } from 'passport-http-bearer';

const JWT_SECRET = process.env.JWT_SECRET!;
passport.use(
	new Strategy((token, done) => {
		jwt.verify(token, JWT_SECRET, (err, decoded) => {
			if (err) {
				return done(null, false);
			}

			return done(null, decoded, { scope: 'none' });
		});
	}),
);

connectToDatabase();

const app = express();
const PORT = process.env.PORT ?? 3000;
const portNumber = Number(PORT);
if (Number.isNaN(portNumber)) {
	throw new Error('Invalid port number');
}

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/auth', authRouter);
app.use('/event', eventRouter);
app.use('/video', videoRouter);
app.use('/tag', tagRouter);

app.listen(portNumber, '0.0.0.0', () => {
	console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
