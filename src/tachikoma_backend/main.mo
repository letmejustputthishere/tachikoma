import Result "mo:base/Result";
import Types "types";
import Error "mo:base/Error";

actor {

  public func getPrice() : async Result.Result<Types.http_response, Text> {

    // create management canister actor reference
    let ic : Types.IC = actor ("aaaaa-aa");

    // make call to management canister to use https outcall feature
    try {
      let httpResponse = await ic.http_request({
        url = "https://api.exchange.coinbase.com/products/ICP-USD/candles?granularity=60&start=1620743971&end=1620744031";
        method = #get;
        max_response_bytes = ?1000 : ?Nat64;
        body = null;
        transform = null;
        headers = [
          { name = "User-Agent"; value = "exchange_rate_canister" },
        ];
      });
      return #ok(httpResponse);
    } catch (error : Error) {
      return #err("Reject message: " # Error.message(error));
    };
  };
};
