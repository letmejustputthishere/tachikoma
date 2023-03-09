import crypto from "crypto";
import secp256k1 from "secp256k1";

export function verify(
    message: string,
    signatureHex: string,
) {
    let signature = new Uint8Array(Buffer.from(signatureHex, "hex"));
    let publicKey = new Uint8Array(Buffer.from(process.env.PUBLIC_KEY!, "hex"));
    let messageHash = new Uint8Array(
        crypto.createHash("sha256").update(message, "utf-8").digest()
    );
    let verified = secp256k1.ecdsaVerify(signature, messageHash, publicKey);
    console.log("verified = ", verified);
    return verified;
}
