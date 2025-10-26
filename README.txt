# PayVVM Monorepo

Modular, multi-app workspace for **gasless PYUSD payments over EVVM**, with:
- **/app** → “EVVMscan”-style live dashboard (Envio-powered) for your EVVM instance(s)
- **/Payvvm** → EVVM init wizard + contracts + scripts (deploy/register/test)
- **/telegram** → Bot + Mini App (POS “card terminal” UX) + Relayer/Fisher
- **/envioftpayvvm** → Scaffold-ETH 2 project extended with **Envio HyperIndex/HyperSync** (first “etherscan-alike” + service deployment console)

> Everything lives in **one repo** (org-owned). Each module can be **developed, built, and deployed independently**.

---

## 1) Repo Layout

```
payvvm/
├─ README.md  ← this file
├─ package.json
├─ pnpm-workspace.yaml
├─ .env.example
│
├─ app/
│  ├─ src/
│  └─ package.json
│
├─ Payvvm/
│  ├─ contracts/
│  ├─ script/
│  ├─ broadcast/
│  └─ package.json
│
├─ telegram/
│  ├─ bot/
│  ├─ miniapp/
│  ├─ relayer/
│  └─ package.json
│
└─ envioftpayvvm/
   ├─ packages/
   │  ├─ nextjs/
   │  ├─ hardhat/
   │  └─ indexer/
   └─ package.json
```

---

## 2) Tech Stack Summary

- **Contracts/EVVM**: Solidity + Foundry
- **Indexing**: Envio HyperIndex + HyperSync
- **Dashboards**: Next.js/React + TypeScript
- **Telegram**: Bot API + Mini App + Relayer (Node + viem)
- **Payments**: PYUSD (Sepolia/Arbitrum Sepolia)
- **Workspace**: pnpm workspaces (recommended)

---

## 3) Workspace Setup

```
pnpm i
```

Copy `.env.example` → `.env` in each folder.

---

## 4) Root Scripts

```
"scripts": {
  "dev:app": "pnpm --filter app dev",
  "dev:telegram": "pnpm --filter telegram dev",
  "dev:envio": "pnpm --filter envioftpayvvm dev",
  "build": "run-p build:*",
  "test:contracts": "pnpm --filter Payvvm test",
  "deploy:evvm": "pnpm --filter Payvvm deploy"
}
```

---

## 5) Module Overview

### /Payvvm
- EVVM wizard, contracts, registry integration.

### /envioftpayvvm
- Scaffold-ETH2 + Envio indexer + EVVM service deployment.

### /app
- Public “EVVMscan” dashboard for payments and fishers.

### /telegram
- Telegram Bot + Mini App + Relayer for gasless UX.

---

## 6) Environments

- **Local**: Anvil + ngrok for Telegram webhook.
- **Testnet**: Sepolia or Arbitrum Sepolia (PYUSD, EVVM Registry).
- **Prod**: Mainnet-ready, modular deploys per folder.

---

## 7) Quickstart

```
pnpm i
cd Payvvm && ./evvm-init.sh
cd ../envioftpayvvm && pnpm dev
cd ../app && pnpm dev
cd ../telegram && pnpm dev
```

---

## 8) Security Notes

- Never commit private keys.
- Use replay protection (nonces).
- Restrict webhook access and secrets.
- Store RPC/API keys securely.
