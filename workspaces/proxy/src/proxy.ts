import express from "express";
import bodyParser from "body-parser";
import "dotenv/config";
import TwitterApi from "twitter-api-v2";

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

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

app.get("/", (req, res) => {
    // using the authenticated client, we can send a tweet on behalf of the user
    client.v2.tweet("hello world!");
    res.send("Tweet sent!");
});

app.listen(port, () => {
    console.log(`Server listening on port ${port}.`);
});
