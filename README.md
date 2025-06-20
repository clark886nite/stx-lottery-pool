 STX Lottery Pool

 **STX Lottery Pool** is a decentralized lottery smart contract built on the Stacks blockchain.  
Participants can buy tickets with STX, and an admin triggers a winner draw. The winner claims the prize pool.

---

 Features

- Users can buy tickets using STX.
- All ticket purchases and participant data are securely stored on-chain.
- Admin manually triggers the winner draw (can integrate with off-chain randomness sources).
- Winner claims the prize pool.
- Read-only functions provide pool, participant, and winner information.

---

 Contract Functions

| Function | Type | Description |
|-----------|------|-------------|
| `buy-ticket` | Public | Allows users to purchase a lottery ticket. |
| `draw-winner` | Public | Admin-only function to draw a winner from ticket holders. |
| `claim-prize` | Public | Winner claims the prize pool (STX balance). |
| `get-pool-status` | Read-only | Returns current pool details (prize balance, ticket count). |
| `get-participant-tickets` | Read-only | Returns the ticket count for a specific participant. |
| `get-winner` | Read-only | Returns the current round’s winner address (if drawn). |

---

 How It Works

1 Users call `buy-ticket` to enter the lottery and transfer STX.  
2 Admin calls `draw-winner` to select a winner (selection logic can be enhanced with off-chain randomness).  
3 Winner calls `claim-prize` to receive the prize pool.  
4 New lottery rounds can be started manually or via contract reset logic.

---

 Notes

- All payments are in micro-STX (1 STX = 1,000,000 micro-STX).
- Winner selection is manually triggered; no built-in randomness (off-chain integration recommended).
- Contract requires off-chain automation for drawing and periodic management.

---

 Development & Deployment

Recommended tool: [Clarinet](https://github.com/hirosystems/clarinet)

### Run checks:
```bash
clarinet check
clarinet test
clarinet deploy
