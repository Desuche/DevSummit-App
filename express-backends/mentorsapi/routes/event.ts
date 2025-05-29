import express from 'express';
const passport = require('passport');
import { 
    getEventsByDate,
    getEventById,
    getAllEvents,
    getEventsByAttendee,
    registerForEvent,
    unregisterForEvent
 } from '../db/event';
import { ObjectId } from 'mongodb';


const router = express.Router();

router.get('/id/:eventId', passport.authenticate('bearer', { session: false }), async (req, res) => {
    const { eventId } = req.params;

    // @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    if (!eventId) {
        res.status(400).json({ message: 'Event ID is required' });
        return;
    }

    const event = await getEventById(new ObjectId(eventId));
    if (event == null){
        throw new Error("Event not found")
    }
    // @ts-ignore
    if (event.attendees.some(id => id.equals(req.user._id))) {
        // @ts-ignore
        event.attendees = [req.user._id];
    } else {
        event.attendees = [];
    }
    res.status(200).json(event);
});

router.get('/', passport.authenticate('bearer', { session: false }), async (req, res) => {
    // @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    const events = await getAllEvents();
    const cleanedEvents = events.map(event => {
        // @ts-ignore
        if (event.attendees.includes(req.user._id)) {
            return {
                ...event,
                // @ts-ignore
                attendees: [req.user._id]
            };
        } else {
            return {
                ...event,
                attendees: []
            };
        }
    });
    res.status(200).json(events);
});

router.get('/bydate', passport.authenticate('bearer', { session: false }), async (req, res) => {
    const { date } = req.query;
// @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    if (!date) {
        res.status(400).json({ message: 'Date is required' });
        return;
    }
    // @ts-ignore
    const events = await getEventsByDate(new Date(date));
    const cleanedEvents = events.map(event => {
        // @ts-ignore
        if (event.attendees.includes(req.user._id)) {
            return {
                ...event,
                // @ts-ignore
                attendees: [req.user._id]
            };
        } else {
            return {
                ...event,
                attendees: []
            };
        }
    });
    res.status(200).json(events);
});

router.get('/registered', passport.authenticate('bearer', { session: false }), async (req, res) => {
    // @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    // @ts-ignore
    const events = await getEventsByAttendee(new ObjectId(req.user._id));
    const cleanedEvents = events.map(event => {
        return {
            ...event,
            // @ts-ignore
            attendees: [req.user._id]
        };
    });
    res.status(200).json(events);
});

router.post('/register', passport.authenticate('bearer', { session: false }), async (req, res) => {
    try{
    const { eventId } = req.body;
// @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    if (!eventId) {
        res.status(400).json({ message: 'Event ID is required' });
        return;
    }
// @ts-ignore
    const result = await registerForEvent(new ObjectId(eventId), new ObjectId(req.user._id));
    if (result) {
        res.status(200).json({ message: 'Registered' });
    } else {
        res.status(400).json({ message: 'Registration failed' });
    }
    return
} catch (err) {
    res.status(400).json({ message: 'Bad request' });
    return;
}
});

router.post('/unregister', passport.authenticate('bearer', { session: false }), async (req, res) => {
    const { eventId } = req.body;
// @ts-ignore
    if (!req.user) {
        res.status(401).json({ message: 'Unauthorized' });
        return;
    }

    if (!eventId) {
        res.status(400).json({ message: 'Event ID is required' });
        return;
    }
// @ts-ignore
    const result = await unregisterForEvent(new ObjectId(eventId), new ObjectId(req.user._id));
    if (result) {
        res.status(200).json({ message: 'Unregistered' });
    } else {
        res.status(400).json({ message: 'Unregistration failed' });
    }
});



export default router;