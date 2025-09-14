# TrTrust_vault

# Remembrance Ledger - Digital Legacy Vault

A decentralized smart contract platform built on Stacks blockchain for preserving digital memories, wills, and personal messages for future generations. Remembrance Ledger enables secure, tamper-proof storage of encrypted legacy content with time-based release mechanisms.

## Features

- **Encrypted Memory Storage**: Store encrypted letters, wills, photos, videos, and documents
- **Time-Based Release**: Automatic content release based on predetermined block heights
- **Multi-Type Support**: Support for letters, wills, photos, videos, and documents
- **Access Control**: Secure recipient-only access after release
- **Emergency Release**: Creator-controlled immediate release functionality
- **Access Logging**: Comprehensive tracking of memory access and interactions
- **Fee Management**: Configurable contract fees with owner controls

## Smart Contract Functions

### Public Functions

- `create-memory`: Store encrypted content with specified recipient and release time
- `release-memory`: Release memory to recipient (creator or automatic after release time)
- `access-memory`: Access released memory content (recipient only)
- `emergency-release`: Immediate release by creator
- `update-contract-fee`: Update contract fees (owner only)

### Read-Only Functions

- `get-memory`: Retrieve memory details with privacy controls
- `get-user-memories`: Get list of memories created by user
- `get-recipient-memories`: Get list of memories for recipient
- `get-contract-stats`: View contract statistics
- `is-memory-ready-for-release`: Check if memory is ready for release

## Installation

1. Install Clarinet:
\`\`\`bash
curl -L https://github.com/hirosystems/clarinet/releases/download/v1.0.0/clarinet-linux-x64.tar.gz | tar xz
\`\`\`

2. Clone the repository:
\`\`\`bash
git clone <repository-url>
cd remembrance-ledger
\`\`\`

3. Install dependencies:
\`\`\`bash
npm install
\`\`\`

## Usage

### Deploy Contract
\`\`\`bash
clarinet deploy --testnet
\`\`\`

### Run Tests
\`\`\`bash
clarinet test
\`\`\`

### Create a Memory
```clarity
(contract-call? .remembrance-ledger create-memory
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7  ;; recipient
  u1                                                ;; memory type (letter)
  "encrypted-content-here"                          ;; encrypted content
  "encrypted-key-here"                              ;; encryption key
  "My Final Message"                                ;; title
  "A heartfelt letter for my family"               ;; description
  u1000                                             ;; release at block 1000
)
