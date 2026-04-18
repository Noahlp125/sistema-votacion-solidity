# Voting System Smart Contract
Smart Contract built in Solidity 0.8.34 as a part of a Blockchain Development Master.

## Features
- Voter whitelist
- Candidate registration
- Time-limited voting
- ETH payment to vote
- Owner fund withdrawal

## How to test
1. Deploy with a duration in seconds (eg.300)
2. Register candidates with registerCandidate
3. Authorice voters with authorizeVoter
4. Vote with 0.01 ETH
5. After time expires, check the winner
