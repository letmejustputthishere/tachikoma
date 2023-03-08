import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Account {
  'owner' : Principal,
  'subaccount' : [] | [Subaccount],
}
export interface DecodedHttpResponse {
  'status' : bigint,
  'body' : string,
  'headers' : Array<http_header>,
}
export type Result = { 'ok' : DecodedHttpResponse } |
  { 'err' : string };
export type Subaccount = Uint8Array | number[];
export interface http_header { 'value' : string, 'name' : string }
export interface http_response {
  'status' : bigint,
  'body' : Uint8Array | number[],
  'headers' : Array<http_header>,
}
export interface _SERVICE {
  'getAccount' : ActorMethod<[], Account>,
  'getPrice' : ActorMethod<[], Result>,
  'transform' : ActorMethod<
    [{ 'context' : Uint8Array | number[], 'response' : http_response }],
    http_response
  >,
}
