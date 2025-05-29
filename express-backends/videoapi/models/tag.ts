import type { ObjectId } from 'mongodb'

export type Tag = {
    _id?: ObjectId;
    name: string;
}
