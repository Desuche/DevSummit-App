import { MongoClient } from 'mongodb';

let client: MongoClient;

export const connectToDatabase = async () => {
	if (client) return;

	const connectionString = process.env.DB_CONNECTION_STRING;
	console.log('Connection string:', connectionString);

	if (!connectionString) {
		throw new Error('Connection string is required');
	}

	client = new MongoClient(connectionString);
	await client.connect();
	console.log('Connected to MongoDB');
};

export const getDatabase = () => {
	if (!client) {
		throw new Error('Call connectToDatabase first');
	}

	return client.db('project');
};
