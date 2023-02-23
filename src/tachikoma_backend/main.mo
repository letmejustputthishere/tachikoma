import Result "mo:base/Result";

actor {
  public func getPrice() : async Result.Result<Text, Text> {
    return #ok("this worked");
  };
};