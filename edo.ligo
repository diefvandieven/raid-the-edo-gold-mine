(* Mining Challenge *)

#include "../utils/bytes.ligo"

(* contract storage *)
type storage is
  record [
    totalMined      : tez;
    challenge       : bytes;
    target          : int;
    lastAdjustment  : timestamp;
    blocksMined     : int;
    solutions       : big_map (bytes, bytes); // big_map( challenge, solution )
    lastReward      : record [
      miner           : address;
      reward          : tez;
      blockTime       : timestamp
    ];

    (* Define some mining params *)
    params          : record [
      blocksPerAdjustment   : int;
      secPerBlock           : int;
      minTarget             : int;
      maxTarget             : int;
    ]
  ]

(* define return for readability *)
type return is list (operation) * storage

(* define noop for readability *)
const noOperations : list (operation) = nil;

(* Inputs *)
type mineParams is michelson_pair(bytes, "nonce", bytes, "solution")

(* Get current mining reward *)
function getMiningReward (const solution : int; const target : int) : tez is
  block {
    const factor : int = target / solution;
    var r : tez := 0tez;
    if factor >= 2 then r := 0.5tez else skip;
    if factor >= 5 then r := 1tez else skip;
    if factor >= 8 then r := 2.5tez else skip;
    if factor >= 10 then r := 5tez else skip;
    if r > Tezos.balance then r := Tezos.balance else skip;
  } with (r)

(* Verify mining solution *)
function verifySolution (const nonce : bytes; const solution : bytes; const solutionInt : int; const s : storage) : bool is
  Crypto.blake2b(Bytes.concat(Bytes.concat(s.challenge, nonce), Bytes.pack(Tezos.sender))) = solution;

(* Adjust mining difficulty *)
function adjustDifficulty (var s : storage) : storage is
  block {
    const currentDiff : int = s.params.maxTarget * 1000000 / s.target;
    const nextDiff : int = currentDiff * (s.params.blocksPerAdjustment * s.params.secPerBlock) / (Tezos.now - s.lastAdjustment);
    s.target := s.params.maxTarget * 1000000 / nextDiff;
    if s.target > s.params.maxTarget then s.target := s.params.maxTarget else skip;
    if s.target < s.params.minTarget then s.target := s.params.minTarget else skip;
    s.lastAdjustment := Tezos.now;
  } with s

(* Mine a new block *)
function mine (const nonce : bytes; const solution : bytes; var s : storage) : return is
  block {
    const solutionInt : int = bytes_to_int(solution);
    if verifySolution(nonce, solution, solutionInt, s) = False then
      failwith ("Invalid")
    else skip;
    case s.solutions[s.challenge] of
        Some (solved) -> failwith ("Solved")
      | None -> skip
      end;
    var operations : list (operation) := nil;
    const reward : tez = getMiningReward(solutionInt, s.target);
    if reward > 0tez then {
      const receiver : contract (unit) = get_contract (Tezos.sender);
      const payoutOperation : operation = transaction (unit, reward, receiver);
      operations := payoutOperation # operations;
    }
    else skip;
    s.totalMined := s.totalMined + reward;
    s.lastReward.miner := Tezos.sender;
    s.lastReward.reward := reward;
    s.lastReward.blockTime := Tezos.now;
    s.solutions[s.challenge] := solution;
    s.blocksMined := s.blocksMined + 1;
    const m : nat = s.blocksMined mod s.params.blocksPerAdjustment;
    if m = 0n then
      s := adjustDifficulty(s);
    else skip;
    s.challenge := Crypto.blake2b(solution);
  } with (operations, s)

(* Main entrypoint *)
function main (const params : mineParams; var s : storage) : return is
  mine(params.0, params.1, s);
