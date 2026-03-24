# Soulon Wallet

A multi-platform Web3 wallet ecosystem targeting Cosmos-based blockchains.

## Architecture

```
soulon-wallet/
├── wallet-app-flutter/    # Flutter mobile & web client (Dart)
├── wallet-app/            # React web dashboard (TypeScript)
├── wallet-extension/      # Chrome browser extension (TypeScript)
├── soulon-deep-chain/     # Blockchain node (Go)
├── soulon-backend/        # Backend API + indexer (Go)
├── deploy/                # Deployment scripts & acceptance reports
└── spec/                  # Cross-platform route mapping specs
```

## Sub-projects

### wallet-app-flutter
Flutter-based wallet with 78 routes covering onboarding, asset management, transactions (send/receive/swap), staking, governance, WalletConnect, and multi-signature workflows. Uses Material 3 dark theme with Backpack-aligned design tokens.

- **SDK**: Flutter >= 3.22, Dart >= 3.3
- **State**: ValueNotifier + immutable state pattern
- **API**: ChainApiContract v1.4.0 (16 endpoints)

### wallet-app
React web dashboard for wallet state monitoring, event tracking, and notifications.

- **Stack**: React 19, React Router 6, Vite 8, TypeScript 5.9
- **Auth**: Session-based with RequireAuth route guard
- **API**: Custom ApiClient with retry, timeout, and lifecycle tracing

### wallet-extension
Chrome browser extension popup with tab navigation (Tokens/Collectibles/Activity), send/receive flows, and settings.

- **Stack**: TypeScript, vanilla DOM
- **State**: Custom publish-subscribe store
- **Routes**: 18 popup routes with stack-based navigation

### soulon-deep-chain
Cosmos-style blockchain node with bank, staking, governance, and distribution modules.

- **Stack**: Go 1.22
- **Modules**: bank (send/balance), staking (delegate/redelegate), gov (proposal/vote/tally), distribution (reward)
- **Tx Types**: 8 transaction types with full validation

### soulon-backend
Production-grade backend with REST API, blockchain event indexer, and gateway.

- **Stack**: Go 1.24, PostgreSQL (pgx), Kafka, Prometheus
- **Services**: API server (SSE notifications, auth challenges), indexer worker, gateway
- **CI**: GitHub Actions (integration, staging drill, chaos testing)

## Quick Start

### Prerequisites
- Flutter >= 3.22
- Go >= 1.22
- Node.js >= 20
- PostgreSQL 16+

### Development

```bash
# Flutter app
cd wallet-app-flutter && flutter run

# React web
cd wallet-app && npm install && npm run dev

# Backend
cd soulon-backend && go run ./cmd/api

# Chain node
cd soulon-deep-chain && go run ./cmd/soulond
```

## License

Proprietary — All rights reserved.
