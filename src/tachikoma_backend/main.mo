import Result "mo:base/Result";
import Types "types";

actor {
  // create management canister actor reference
  let ic : Types.IC = actor ("aaaaa-aa");

  public func getPrice() : async Result.Result<Text, Text> {
    return #ok("this worked");
  };
};
