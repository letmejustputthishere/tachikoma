import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Types "types";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";

module {
  public func decodeBody(response : Types.http_response) : Types.DecodedHttpResponse {
    switch (Text.decodeUtf8(Blob.fromArray(response.body))) {
      case null { { response with body = "" } };
      case (?decoded) { { response with body = decoded } };
    };
  };

  public func deriveAccountFromCaller(principal : Principal, canisterId : Principal) : Types.Account {
    {
      owner = canisterId;
      subaccount = deriveSubaccountFromPrincipal(principal);
    };
  };

  public func deriveSubaccountFromPrincipal(principal : Principal) : ?Blob {
    let bytes : [Nat8] = Blob.toArray(Principal.toBlob(principal));
    let n = bytes.size();
    let zeroCount = 32 - n;
    ?Blob.fromArray(
      Array.tabulate(
        32,
        func(i : Nat) : Nat8 {
          if (i < zeroCount) { Nat8.fromNat(0) } else {
            bytes[i - zeroCount];
          };
        },
      ),
    );
  };
};
