import Result "mo:base/Result";
import Types "types";
import Error "mo:base/Error";
import Cycles "mo:base/ExperimentalCycles";
import { decodeBody; deriveAccountFromCaller; deriveSubaccountFromPrincipal } "helpers";
import CkBtcLedger "canister:ledger";
import Principal "mo:base/Principal";
import Hex "mo:encoding.mo/Hex";
import Sha256 "mo:motoko-lib/Sha256";
import Text "mo:base/Text";
import Blob "mo:base/Blob";
import JSON "mo:json.mo/JSON";

actor Tachikoma {
  // create management canister actor reference
  let ic : Types.IC = actor ("aaaaa-aa");

  // return the ECDSA public key of the canister
  // we keep this an update method to make sure no malicious replica tamper
  // with the public key
  public func public_key() : async Result.Result<Text, Text> {
    try {
      let { public_key } = await ic.ecdsa_public_key({
        canister_id = null;
        derivation_path = [];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      #ok(Hex.encode(public_key));
    } catch (err) {
      #err("Reject message: " # Error.message(err));
    };
  };

  func sign(message : Text) : async* Result.Result<Text, Text> {
    try {
      let message_hash = Blob.toArray(Sha256.fromBlob(#sha256, Text.encodeUtf8(message)));
      Cycles.add(30_000_000_000);
      let { signature } = await ic.sign_with_ecdsa({
        message_hash;
        derivation_path = [];
        key_id = { curve = #secp256k1; name = "dfx_test_key" };
      });
      #ok(Hex.encode(signature));
    } catch (err) {
      #err("Reject message: " # Error.message(err));
    };
  };

  public shared ({ caller }) func getAccount() : async Types.Account {
    deriveAccountFromCaller(caller, Principal.fromActor(Tachikoma));
  };

  public shared ({ caller }) func sendTweet(message : Text) : async Result.Result<Types.DecodedHttpResponse, Text> {
    // set an upper limit for the message length
    // please note that this is merely to avoid high
    // costs for the http outcalls, as they are increasing linearly
    // with the message length. the validation of the tweet length happens
    // client side in the users browser.
    if (Text.size(message) > 500) {
      return #err("Message is too long. Please keep it below 500 characters.");
    };

    // check ckBTC balance for the callers dedicated account
    let balance = await CkBtcLedger.icrc1_balance_of(
      deriveAccountFromCaller(caller, Principal.fromActor(Tachikoma))
    );

    // check if the account has enough funds to pay for the service
    if (balance < 100_000_000) {
      return #err("Not enough funds available in the Account. Make sure you send at least 1 ckBTC.");
    };

    try {
      // if enough funds were sent, move them to the canisters default account
      let transferResult = await CkBtcLedger.icrc1_transfer(
        {
          amount = balance;
          from_subaccount = deriveSubaccountFromPrincipal(caller);
          created_at_time = null;
          fee = null;
          memo = null;
          to = {
            owner = Principal.fromActor(Tachikoma);
            subaccount = null;
          };
        }
      );

      // it could be that the transfer failed, so we check for that
      switch (transferResult) {
        case (#Err(transferError)) {
          return #err("Couldn't transfer funds to default account:\n" # debug_show (transferError));
        };
        case (_) {};
      };
    } catch (error : Error) {
      return #err("Reject message: " # Error.message(error));
    };

    // create a signature on the message
    var hexSignature = "";
    let result = await* sign(message);
    switch (result) {
      case (#ok(value)) { hexSignature := value };
      case (#err(error)) { return #err error };
    };

    // create JSON object with the message and the signature
    let json : Text = JSON.show(#Object([("message", #String(message)), ("signature", #String(hexSignature))]));

    // add cycles to next remote call
    Cycles.add(526_200_000);

    // make call to management canister to use http outcall feature
    try {
      let httpResponse = await ic.http_request({
        url = "http://127.0.0.1:3000/tweet";
        method = #post;
        max_response_bytes = ?500 : ?Nat64;
        body = ?Blob.toArray(Text.encodeUtf8(json));
        transform = ?{
          function = transform;
          context = [];
        };
        headers = [
          { name = "User-Agent"; value = "exchange_rate_canister" },
        ];
      });
      return #ok(decodeBody(httpResponse));
    } catch (error : Error) {
      return #err("Reject message: " # Error.message(error));
    };
  };

  // the transform method required by the http_request method
  public query func transform({
    context : [Nat8];
    response : Types.http_response;
  }) : async Types.http_response {
    {
      response with headers = []; // not intersted in the headers
      body = []; // not interested in the body
    };
  };
};
