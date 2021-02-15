import hashlib
import sys
import random
from pytezos import pytezos

# Given the contract, find the target value and calculate the minimum
# number of 0s required at the front of a valid solution hash
def min_0s_for_prize(contract):
    target = contract.storage()['target']
    max_num = int(target / 2)
    hex_len = len(hex(max_num)) - 3
    return 64 - hex_len

# Given the contract, get the current challenge value
def get_challenge(contract):
    return contract.storage()['challenge']

# Given the contract, get the remaining prize balance
def get_balance_remaining(contract):
    return 100000000 - contract.storage()['totalMined']

# Given the contract submit a (nonce, solution) transaction
# NOTE: As written this method of submitting a transaction
#       uses about 5x the required transaction fees. You
#       might want to look into how to predict better fees.
def send_transaction(contract, nonce, solution):
    return contract.default(nonce, solution).operation_group.inject()

############## STUFF YOU NEED TO ENTER #######################
base58key = '<base58 private key>'                        # Your base58 encrypted private key
address_bytes = bytes.fromhex("<hex address string>")     # Produced in ligo script
contract_address = 'KT1Udix7b2UUnnqSzAk6JsqDy7m1ecwTG1LB' # The contract address
##############################################################

pytezos = pytezos.using(shell='https://mainnet-tezos.giganode.io', key=base58key)
contract = pytezos.contract(contract_address)

challenge_bytes = get_challenge(contract)
min0s = "0" * min_0s_for_prize(contract)

print('running with challenge:', challenge_bytes.hex())
print('current difficulty:', min0s)

while True:
    # Pick a random number
    nonce_bytes = random.randbytes(16)

    # Generate a solution hash
    tohash = challenge_bytes + nonce_bytes + address_bytes
    solution = hashlib.blake2b(tohash, digest_size=32).hexdigest()

    # Check if the current solution matches the current difficulty test
    if solution.startswith(min0s):
        print("****************FOUND********************")
        print("nonce: [%s], solution: [%s], challenge: [%s]" % (nonce_bytes.hex(), solution, challenge_bytes.hex()))
        print(send_transaction(contract, nonce_bytes, solution))

        # Poll the contract for a new challenge value every 5 seconds
        # WARNING: if you are in a mining battle with someone
        #          or if the transaction fails for whatever reason,
        #          this loop may cause you to spin unnecessarily
        new_challenge = challenge_bytes
        while new_challenge == challenge_bytes:
            print("polling for new challenge")
            new_challenge = get_challenge(contract)
            time.sleep(5)

        # Once the challenge value has updated, check the contracts
        # remaining balance. If it is empty, time to shut 'er down.
        if get_balance_remaining(contract) <= 0:
            print("****************Mine Drained********************")
            sys.exit(0)

        challenge_bytes = new_challenge
        min0s = "0" * min_0s_for_prize(contract)
        print('running with new challenge:', challenge_bytes.hex())
        print('current difficulty:', min0s)
