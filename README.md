# StableAmp - Stablecoin Liquidity Amplifier

## What It Does
A simple liquidity amplification system for stablecoins on Stacks. Users deposit stablecoins, the system amplifies their liquidity through smart contract mechanisms, and users earn enhanced yields.

## Core Feature (MVP)
- **Liquidity Amplification**: Deposit 100 USDC, get 200 USDC worth of trading power
- **STX Integration**: Uses STX for governance and fee payments
- **Bitcoin Security**: Leverages Stacks' Bitcoin settlement for security

## Why This Needs Stacks
- **Bitcoin Finality**: Large liquidity operations need Bitcoin-grade security
- **STX Economics**: Amplification rewards paid in STX from PoX
- **Clarity Precision**: Complex liquidity math needs predictable execution

## Technical Approach
1. Users deposit stablecoins into amplification pool
2. Smart contract provides 2x trading liquidity
3. Trading fees + STX rewards = enhanced yields
4. Bitcoin settlement ensures security for large operations

## Getting Started
```bash
git clone [repo]
clarinet check
```

## Files Structure
```
├── contracts/
│   ├── stable-amp.clar           # Main amplification logic
│   └── traits/sip-010-trait.clar # Token interface
├── tests/
│   └── stable-amp_test.ts
└── README.md
```

## MVP Features
- [x] Basic pool creation
- [x] Deposit/withdraw stablecoins  
- [x] 2x liquidity amplification
- [x] Fee collection in STX
- [ ] Enhanced yield distribution
- [ ] Multi-user support
