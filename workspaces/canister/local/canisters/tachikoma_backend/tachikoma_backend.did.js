export const idlFactory = ({ IDL }) => {
  const Subaccount = IDL.Vec(IDL.Nat8);
  const Account = IDL.Record({
    'owner' : IDL.Principal,
    'subaccount' : IDL.Opt(Subaccount),
  });
  const http_header = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const DecodedHttpResponse = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Text,
    'headers' : IDL.Vec(http_header),
  });
  const Result = IDL.Variant({ 'ok' : DecodedHttpResponse, 'err' : IDL.Text });
  const http_response = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(http_header),
  });
  return IDL.Service({
    'getAccount' : IDL.Func([], [Account], []),
    'getPrice' : IDL.Func([], [Result], []),
    'transform' : IDL.Func(
        [
          IDL.Record({
            'context' : IDL.Vec(IDL.Nat8),
            'response' : http_response,
          }),
        ],
        [http_response],
        ['query'],
      ),
  });
};
export const init = ({ IDL }) => { return []; };
