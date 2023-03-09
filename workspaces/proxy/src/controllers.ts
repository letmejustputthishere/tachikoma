import { NextFunction, Request, Response } from "express";
import Joi from "joi";

// Define the schema for the RequestBody interface
const schema = Joi.object({
    message: Joi.string().required(),
    signature: Joi.string().required(),
});

export async function validateRequestBody(
    req: Request,
    resp: Response,
    next: NextFunction
) {
    // Validate the request body against the schema
    const { error } = schema.validate(req.body);
    if (error) {
        console.log(error.message);
        resp.status(400).send(error.message);
    } else {
        next();
    }
}
