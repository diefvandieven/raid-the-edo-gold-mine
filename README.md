# Raiding the EDO Gold Mine
The Python Miner I built to raid the funds in the EDO Gold Mine contract on the Tezos Blockchain.

https://diefvandieven.medium.com/raiding-the-edo-gold-mine-bc5ae5941d4a

## Requirements
* Docker
* Python 3.9 (see notes for alternatives)
* Tezos Wallet

## Getting Started
1. Generate your Tezos address byte string by updating the `get_packed_address.ligo` file with your Tezos address. Then run the script:
  ```sh
  > ./get_packed_address.sh
  0x050a000000160000f7011de44aa482aa6a4c9f4bf6e56960c889088a
  ```
2. Update the personal data in the `mine_edo.py` script:
  * base58key - You can easily get this in the Account Settings if you are using Thanos Wallet.
  * account_bytes - This is the hex string you generated with the `get_packed_address.ligo` script.
  * contract_address - Change this if you are running against a different contract
3. Flip the switch!
  ```sh
  python3 mine_edo.py
  ```

## Notes
* Python 3.9 is necessary only for the `random.randbytes(16)`. If you want to use a lower version of Python, no problem! Just change this line to get the bytes some other way. Ex. `bytes(<some number>)`
* **USE AT YOUR OWN RISK** This code, when given your private key, DOES make transactions. Please review all the code carefully before running. I am not liable for any unintentional or erroneous transactions coming from this code.
* There was some last minute refactoring of this code for readability and to remove sensitive info, I hope it works, but there may be syntax issues. Shoot me a note and I can help out.
