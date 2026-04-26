# VENOM Council — Worldview-Agnostic Governance Layer

**Parallel exploration repo** for pluralistic, rotating validator councils that work across Christian, Jewish, Muslim, secular, agnostic, and other worldviews.

**Goal**: Build technical primitives that allow different worldview branches to:
- Maintain internal trust rules (e.g. 2–3 mutual validators)
- Participate equally in a global inter-branch council
- Form "synthetic collaboration entities" where their top trusted nodes show strongest mutual agreement
- Keep the entire system **valid regardless of any specific worldview**

This repo focuses on **tokenomics** (generalized tithing / charitable redirection) and **validation mechanics** (attestation-based trust + rotating councils). It is deliberately **faith-agnostic** while remaining easy to merge back into the main `venom-node` repository later.

---

## Current Components (v0.1)

### 1. TitheManager.sol
Generalized redirection contract with built-in presets:
- `useChristianTithe()` → 10%
- `useZakat()` → 2.5%
- `useTzedakah()` → 10%
- `useSecular(customBps)`
- Fully custom rates + labeled presets

Can be called from `PilotEscrow.closeCampaign()` (or any future payment flow). Recipients and weighting are fully owner/governance controlled.

### 2. CouncilRegistry.sol
The core agnostic governance primitive:
- Registers worldview "branches" (`christian`, `jewish`, `muslim`, `secular`, `agnostic`, …)
- Each branch maintains its own validator list
- Trust earned via mutual attestations (generalized, not creed-specific) + merit metrics (evaluations, low slashing, stake, uptime — pulled from main `VenomRegistry`)
- Rotating "Top-N" council per branch (default 3)
- Global inter-branch council formed from top slices of each branch
- Simple event-based rotation (full on-chain sorting can be added later)

### Future Components (planned)
- `AgreementFactory.sol` — deploys lightweight multi-sig or custom "Synthetic Collaboration Contracts" when two branches’ top validators reach high mutual attestation overlap.
- Integration helpers for `aggregator/p2p.js` and `eval_engine` (attestation publishing, council rotation signals).
- Dashboard widgets showing council composition and cross-branch agreement scores.

---

## Design Principles (for long-term mergeability)

1. **Minimal & Focused** — Each contract does one thing well.
2. **Interface-first** — Easy to plug into existing `VenomRegistry` and `PilotEscrow` via simple references.
3. **Owner / Governance ready** — All sensitive functions are `onlyOwner`; can be handed to a timelock or DAO later.
4. **Event-rich** — Everything is indexable for off-chain dashboards and reputation oracles.
5. **Worldview-agnostic by default** — No hardcoded religious rules. Presets and branch names are just convenient labels.
6. **Merit + Representation balance** — Council composition can combine attestation trust, technical performance, stake weight, and (optional) demographic branch quotas.

---

## Suggested Repo Name & Structure

**Recommended parallel repo**: `https://github.com/realVenomNetwork/venom-council`

```
venom-council/
├── contracts/
│   ├── TitheManager.sol          # Generalized tithing with worldview presets
│   ├── CouncilRegistry.sol       # Branch + rotating council + attestation engine
│   └── (future) AgreementFactory.sol
├── scripts/
│   └── deploy_council.js
├── docs/
│   └── ARCHITECTURE.md
├── README.md
└── package.json (minimal, for Hardhat if needed)
```

---

## Integration Path Back to Main Repo

When ready, these contracts can be moved into `venom-node/contracts/governance/` with almost zero changes. The only required updates in the main repo are:

- Add `TitheManager` reference + one-line change in `PilotEscrow.closeCampaign()`
- Add `CouncilRegistry` reference + optional `isActiveOracle` enhancement in `VenomRegistry`
- Add attestation publishing functions in `aggregator/p2p.js`

All existing testnet flows continue to work unchanged.

---

## Current Status (April 2026)

- TitheManager with presets: ✅ implemented
- CouncilRegistry (branch + attestation + rotating council skeleton): ✅ implemented
- Next: AgreementFactory + JS integration helpers + demo deployment script

---

**License**: MIT (same as main venom-node)  
**Maintained by**: realVenomNetwork (technical contributions welcome from any worldview)

---

*“The structure must remain valid regardless of worldview.”*

This repo exists to explore exactly that. Contributions that strengthen the technical primitives while preserving pluralism are highly valued.
