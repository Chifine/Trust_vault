
# TrustVault – Decentralized Escrow Service

**TrustVault** is a decentralized escrow platform built on the Stacks blockchain. It enables secure **peer-to-peer transactions** with automated dispute resolution and a built-in arbitration system. Buyers and sellers can transact with confidence while arbitrators step in only when disputes arise.

---

## 🚀 Features

* **Escrow Creation** – Buyers can create an escrow agreement with sellers.
* **Funds Deposit** – Buyers fund escrows with STX (amount + fee).
* **Completion Mechanism**

  * Buyer confirms successful delivery, **or**
  * Seller provides a **completion code** to unlock funds.
* **Dispute Handling** – Either party may initiate a dispute within the dispute window.
* **Arbitration** – A designated arbitrator resolves disputes by voting in favor of the buyer or seller.
* **Platform Fees** – A configurable platform fee (default: **2.5%**) is collected per transaction.
* **Transparency** – On-chain record of all escrow agreements, disputes, and resolutions.

---

## 📜 Escrow Lifecycle

1. **Create Escrow** – Buyer defines seller, amount, description, optional arbitrator, and completion code.
2. **Fund Escrow** – Buyer deposits STX (amount + fee) into the smart contract.
3. **Completion** –

   * Buyer confirms delivery **or**
   * Seller submits completion code (if enabled).
     Funds are then released to the seller, and the platform fee is collected.
4. **Dispute** – If an issue arises, either party may raise a dispute before the **24-hour dispute deadline**.
5. **Resolution** – Arbitrator casts a vote.

   * **Favor buyer** → Refund issued.
   * **Favor seller** → Payment released.
     Platform fee is still collected.
6. **Escrow Closure** – Escrow state updated to **Completed**, **Resolved**, or **Cancelled**.

---

## ⚖️ Escrow States

| State     | Code | Description                                 |
| --------- | ---- | ------------------------------------------- |
| Pending   | `u1` | Escrow created but not funded.              |
| Funded    | `u2` | Buyer deposited funds, awaiting completion. |
| Completed | `u3` | Transaction successfully closed.            |
| Disputed  | `u4` | Dispute initiated within the deadline.      |
| Resolved  | `u5` | Arbitrator resolved the dispute.            |
| Cancelled | `u6` | Escrow canceled before funding.             |

---

## ⚡ Key Functions

### Public Functions

* `create-escrow` → Create a new escrow agreement.
* `fund-escrow` → Buyer deposits funds.
* `complete-escrow` → Buyer confirms delivery or seller provides completion code.
* `initiate-dispute` → Buyer or seller raises a dispute.
* `vote-dispute` → Arbitrator resolves dispute.

### Read-Only Functions

* `get-escrow` → Fetch escrow details by ID.
* `get-user-escrows` → Retrieve all escrows linked to a user.
* `get-platform-stats` → Platform statistics (total escrows, fee rate, dispute period).

---

## 🔐 Security & Safeguards

* Only **buyer** can fund an escrow.
* Only **buyer or seller** can raise a dispute.
* Only the **designated arbitrator** can resolve disputes.
* Funds are securely locked in the contract until a valid resolution occurs.

---

## 📊 Platform Parameters

* **Platform Fee Rate** → `2.5%` (configurable).
* **Dispute Period** → `1440 blocks (~24 hours)`.
* **Escrow ID Limit per User** → `50 active escrows`.

---

## 🛠️ Error Codes

| Code   | Meaning                        |
| ------ | ------------------------------ |
| `u100` | Not authorized.                |
| `u101` | Escrow not found.              |
| `u102` | Invalid escrow state.          |
| `u103` | Insufficient funds.            |
| `u104` | Dispute period expired.        |
| `u105` | Escrow already disputed.       |
| `u999` | Escrow list overflow for user. |

---

## 📌 Example Workflow

1. **Buyer** creates escrow → `create-escrow`.
2. **Buyer** funds escrow → `fund-escrow`.
3. **Seller** delivers goods/service.
4. **Buyer** completes escrow OR **Seller** provides completion code → `complete-escrow`.
5. If dispute → `initiate-dispute`.
6. **Arbitrator** resolves → `vote-dispute`.

---

## 🔮 Future Enhancements

* Multi-arbitrator voting system.
* Support for milestone-based payments.
* Token-based fee payments (e.g., USDC, wBTC).
* Decentralized arbitration (community-driven voting).

