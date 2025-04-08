# 🗳️ On-Chain Voting Smart Contract

A simple and transparent on-chain voting system built with Solidity and Foundry. This contract allows registered users to cast votes on the Ethereum blockchain, ensuring fairness, security, and immutability of results.

---

## 📦 Project Structure
0x04-OnChainVoting/ ├── lib/ # Dependencies (e.g., forge-std) ├── script/ # Deployment scripts ├── src/ # Main contract(s) │ └── OnChainVoting.sol ├── test/ # Unit tests ├── foundry.toml # Foundry config file └── README.md # Project documentation

---

## ⚙️ Features

- ✅ Candidate registration
- ✅ One person, one vote
- ✅ Live vote count
- ✅ Automatic winner calculation
- ✅ 100% on-chain transparency

---

## 🛠️ Tech Stack

- **Solidity** — smart contract language  
- **Foundry** — testing, scripting, and deploying  
- **Forge-std** — standard library for testing

---

## 🚀 Getting Started

### 1. Clone the repo

```bash
git clone https://github.com/YOUR-USERNAME/0x04-OnChainVoting.git
cd 0x04-OnChainVoting
```
### 2. Install dependencies

```
forge install
forge test
forge script script/Deploy.s.sol --broadcast --rpc-url <YOUR_RPC_URL>

```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
