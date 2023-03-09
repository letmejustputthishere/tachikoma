import express, { Request, Response } from "express";
import "dotenv/config";
import TwitterApi from "twitter-api-v2";
import { verify } from "./helpers";
import { RequestBody } from "./types";
import { validateRequestBody } from "./controllers";

// create a new oauth 1.0a authenticated twitter client
// make sure to have your .env file in the root of this project
const client = new TwitterApi({
    appKey: process.env.CONSUMER_KEY!,
    appSecret: process.env.CONSUMER_SECRET!,
    accessToken: process.env.ACCESS_TOKEN!,
    accessSecret: process.env.ACCESS_TOKEN_SECRET!,
}).readWrite;

const app = express();
const port = 3000;

app.use(express.json());

app.post(
    "/tweet",
    validateRequestBody,
    (req: Request<{}, {}, RequestBody>, res: Response) => {
        let { message, signature } = req.body;

        // if we can verify the signature, we tweet the message
        if (verify(message, signature)) {
            // using the authenticated client, we can send a tweet on behalf of the user
            client.v2.tweet(message);
            res.send("Tweet sent!");
        } else {
            res.status(400).send("Invalid signature.");
        }
    }
);

app.listen(port, () => {
    console.log(`Server listening on port ${port}.`);
});
