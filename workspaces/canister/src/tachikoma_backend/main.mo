import Result "mo:base/Result";
import Types "types";
import Error "mo:base/Error";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import { decodeBody; deriveAccountFromCaller; deriveSubaccountFromPrincipal } "helpers";
import CkBtcLedger "canister:ledger";
import Principal "mo:base/Principal";

actor Tachikoma {

  public shared ({ caller }) func getAccount() : async Types.Account {
    deriveAccountFromCaller(caller, Principal.fromActor(Tachikoma));
  };

  public shared ({ caller }) func getPrice() : async Result.Result<Types.DecodedHttpResponse, Text> {
    // check ckBTC balance for the callers dedicated account
    let balance = await CkBtcLedger.icrc1_balance_of(
      deriveAccountFromCaller(caller, Principal.fromActor(Tachikoma)),
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
        },
      );

      switch (transferResult) {
        case (#Err(transferError)) {
          return #err("Couldn't transfer funds to default account:\n" # debug_show (transferError));
        };
        case (_) {};
      };
    } catch (error : Error) {
      return #err("Reject message: " # Error.message(error));
    };

    // create management canister actor reference
    let ic : Types.IC = actor ("aaaaa-aa");

    // add cycles to next remote call
    ExperimentalCycles.add(514_600_000);

    // make call to management canister to use http outcall feature
    try {
      let httpResponse = await ic.http_request({
        url = "https://api.exchange.coinbase.com/products/ICP-USD/candles?granularity=60&start=1620743971&end=1620744031";
        method = #get;
        max_response_bytes = ?1000 : ?Nat64;
        body = null;
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

  public query func transform({
    context : [Nat8];
    response : Types.http_response;
  }) : async Types.http_response {
    {
      response with headers = []; // not intersted in the headers
    };
  };
};
