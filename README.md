# IndustryStandards

A professional voting platform for technical specifications and best practice adoption built on the Stacks blockchain. IndustryStandards enables stakeholders to propose, vote on, and track the adoption of technical standards while maintaining a reputation-based governance system.

## Features

- **Proposal Management**: Create and manage proposals for technical standards and best practices
- **Democratic Voting**: Stakeholder voting system with time-bounded voting periods
- **Reputation System**: Earn reputation through participation (voting and proposing)
- **Authorization Controls**: Multi-tier access control with owner privileges and authorized proposers
- **Transparent Governance**: All proposals, votes, and outcomes are publicly visible on-chain
- **Emergency Controls**: Contract pause/unpause functionality for emergency situations

## Technical Specifications

- **Blockchain**: Stacks
- **Language**: Clarity v2
- **Epoch**: 2.5
- **Contract Name**: IndustryStandards
- **Version**: 1.0.0

### Key Parameters

- **Minimum Reputation to Propose**: 100 points
- **Voting Period**: 2,016 blocks (~2 weeks, assuming 10-minute blocks)
- **Reputation per Vote**: 10 points
- **Reputation per Proposal**: 50 points

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity smart contract development toolkit
- [Node.js](https://nodejs.org/) v16 or higher
- [Git](https://git-scm.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd IndustryStandards
```

2. Install dependencies:
```bash
cd IndustryStandards_contract
npm install
```

3. Run tests:
```bash
npm test
```

4. Start development environment:
```bash
clarinet console
```

## Usage Examples

### Creating a Proposal

```clarity
;; Initialize user (first-time only)
(contract-call? .IndustryStandards initialize-user)

;; Create a proposal
(contract-call? .IndustryStandards create-proposal
  u"JSON API Standard v3.0"
  u"Proposal to adopt JSON API v3.0 as the standard for REST API responses")
```

### Voting on a Proposal

```clarity
;; Vote in favor of proposal #1
(contract-call? .IndustryStandards vote-on-proposal u1 true)

;; Vote against proposal #1
(contract-call? .IndustryStandards vote-on-proposal u1 false)
```

### Checking Proposal Status

```clarity
;; Get detailed proposal information
(contract-call? .IndustryStandards get-proposal u1)

;; Get proposal summary
(contract-call? .IndustryStandards get-proposal-summary u1)
```

### Finalizing a Proposal

```clarity
;; Finalize proposal after voting period ends
(contract-call? .IndustryStandards finalize-proposal u1)
```

## Contract Functions Documentation

### Public Functions

#### User Management

- **`initialize-user()`**: Initialize a new user's reputation profile
  - Returns: `(ok bool)` - true if new user, false if already exists

#### Proposal Management

- **`create-proposal(title, description)`**: Create a new proposal
  - Parameters:
    - `title`: `(string-utf8 100)` - Proposal title
    - `description`: `(string-utf8 500)` - Detailed description
  - Requirements: Minimum 100 reputation or authorized proposer status
  - Returns: `(ok uint)` - New proposal ID

- **`vote-on-proposal(proposal-id, vote-for)`**: Cast a vote on an active proposal
  - Parameters:
    - `proposal-id`: `uint` - ID of the proposal
    - `vote-for`: `bool` - true for yes, false for no
  - Requirements: Proposal must be active and within voting period
  - Returns: `(ok bool)`

- **`finalize-proposal(proposal-id)`**: Finalize proposal after voting period
  - Parameters:
    - `proposal-id`: `uint` - ID of the proposal
  - Requirements: Voting period must have ended
  - Returns: `(ok string-ascii)` - Final status ("passed" or "rejected")

#### Administration (Owner Only)

- **`authorize-proposer(user)`**: Grant proposal creation rights to a user
- **`revoke-proposer(user)`**: Remove proposal creation rights from a user
- **`toggle-contract-active()`**: Emergency pause/unpause contract functionality

### Read-Only Functions

- **`get-proposal(proposal-id)`**: Get complete proposal details
- **`get-user-vote(proposal-id, user)`**: Get user's vote on a specific proposal
- **`get-user-reputation(user)`**: Get user's reputation and statistics
- **`is-authorized-proposer(user)`**: Check if user is authorized to create proposals
- **`get-proposal-counter()`**: Get total number of proposals created
- **`is-contract-active()`**: Check if contract is currently active
- **`get-proposal-summary(proposal-id)`**: Get proposal summary with vote counts

### Error Codes

- **ERR-NOT-AUTHORIZED (100)**: Insufficient permissions
- **ERR-PROPOSAL-NOT-FOUND (101)**: Proposal does not exist
- **ERR-ALREADY-VOTED (102)**: User has already voted on this proposal
- **ERR-VOTING-ENDED (103)**: Voting period has ended
- **ERR-VOTING-NOT-ENDED (104)**: Voting period still active
- **ERR-INVALID-VOTE (105)**: Invalid vote format
- **ERR-INSUFFICIENT-REPUTATION (106)**: User lacks required reputation

## Deployment Guide

### Testnet Deployment

1. Configure network settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --testnet
clarinet deployments apply -p deployments/default.testnet-plan.yaml
```

### Mainnet Deployment

1. Configure network settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy using Clarinet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply -p deployments/default.mainnet-plan.yaml
```

### Post-Deployment Setup

1. Initialize the contract owner account
2. Authorize initial proposers if needed
3. Create initial governance proposals
4. Communicate contract address to stakeholders

## Security Notes

### Access Controls

- **Contract Owner**: Has emergency powers (pause/unpause, authorize proposers)
- **Authorized Proposers**: Can create proposals regardless of reputation
- **Regular Users**: Must earn 100 reputation points to create proposals

### Governance Security

- **Time-Bounded Voting**: 2-week voting periods prevent rushed decisions
- **One Vote Per User**: Prevents vote manipulation
- **Immutable Records**: All votes and proposals are permanently recorded
- **Reputation System**: Encourages long-term participation and quality proposals

### Emergency Procedures

- Contract can be paused by owner in case of discovered vulnerabilities
- When paused, no new proposals can be created or votes cast
- Existing data remains accessible in read-only mode

### Best Practices

1. **Proposal Creation**: Ensure proposals are well-documented and specific
2. **Voting Participation**: Active participation improves governance quality
3. **Reputation Building**: Consistent engagement builds voting influence
4. **Security Monitoring**: Regular monitoring of contract activity recommended

## Development

### Running Tests

```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

### Project Structure

```
IndustryStandards_contract/
├── contracts/
│   └── IndustryStandards.clar    # Main contract
├── tests/                        # Test files
├── settings/                     # Network configurations
│   ├── Devnet.toml
│   ├── Testnet.toml
│   └── Mainnet.toml
├── Clarinet.toml                 # Project configuration
└── package.json                  # Dependencies and scripts
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For technical support or questions about the IndustryStandards platform, please create an issue in the project repository or contact the development team.